// Pure rules for the `ai` Edge Function: who may use what, request
// validation, cache keys and cost. No I/O here, so it is unit-tested directly
// (policy_test.ts).

/** The model every AI feature uses. Change it here; no app update needed. */
export const MODEL = "claude-sonnet-5-5";

/**
 * Bump when a prompt in prompts.ts changes, so cached results written with the
 * old prompt stop matching.
 */
export const PROMPT_VERSION = 1;

/** Generations a regular scouter may run per UTC day. Cache hits are free. */
export const DEFAULT_DAILY_LIMIT = 20;

/** Team-wide spending ceilings in USD. Override with env vars. */
export const DEFAULT_MONTH_CAP_USD = 20;
export const DEFAULT_YEAR_CAP_USD = 48;

/** Largest request body accepted, in bytes. */
export const MAX_BODY_BYTES = 400_000;

export type Kind = "team_summary" | "match_brief" | "picklist_review" | "chat";
export const KINDS: readonly Kind[] = [
  "team_summary",
  "match_brief",
  "picklist_review",
  "chat",
];

/** Kinds whose result depends only on their payload, so it can be shared. */
export const CACHEABLE: ReadonlySet<Kind> = new Set<Kind>([
  "team_summary",
  "match_brief",
  "picklist_review",
]);

export interface Profile {
  role: string | null;
  ai_access: boolean | null;
}

export interface Access {
  /** Signed in with an allowed account at all. */
  allowed: boolean;
  isAdmin: boolean;
  /** Admin or AI role: no daily limit, plus chat and match briefs. */
  unlimited: boolean;
  kinds: Kind[];
}

/**
 * What a signed-in user may do. Admins come from `profiles.role`; everyone
 * else needs an email on one of [allowedDomains] (the app checks the same
 * domains at sign-in, but the server can't trust the app).
 */
export function accessFor(
  email: string | null | undefined,
  profile: Profile | null,
  allowedDomains: readonly string[],
): Access {
  const role = profile?.role ?? "scout";
  const isAdmin = role === "admin" || role === "super_admin";
  const domain = (email ?? "").toLowerCase().split("@")[1] ?? "";
  const allowed = isAdmin || allowedDomains.includes(domain);
  if (!allowed) {
    return { allowed: false, isAdmin: false, unlimited: false, kinds: [] };
  }
  const unlimited = isAdmin || profile?.ai_access === true;
  const kinds: Kind[] = ["team_summary"];
  if (unlimited) kinds.push("match_brief", "chat");
  if (isAdmin) kinds.push("picklist_review");
  return { allowed, isAdmin, unlimited, kinds };
}

export interface ChatTurn {
  role: "user" | "assistant";
  text: string;
}

export interface GenerateRequest {
  kind: Kind;
  eventKey: string;
  payload: Record<string, unknown>;
  /** Chat only: the conversation so far, ending with the user's question. */
  messages: ChatTurn[];
}

const EVENT_KEY = /^\d{4}[a-z0-9]{1,24}$/;
const MAX_TURNS = 40;
const MAX_TURN_CHARS = 4000;

/** Parses and checks a `generate` body. Returns an error string if invalid. */
export function parseGenerate(body: unknown): GenerateRequest | string {
  if (typeof body !== "object" || body === null) return "Body must be JSON.";
  const b = body as Record<string, unknown>;
  if (!KINDS.includes(b.kind as Kind)) return "Unknown kind.";
  const kind = b.kind as Kind;
  if (typeof b.eventKey !== "string" || !EVENT_KEY.test(b.eventKey)) {
    return "Bad eventKey.";
  }
  if (
    typeof b.payload !== "object" || b.payload === null ||
    Array.isArray(b.payload)
  ) {
    return "payload must be an object.";
  }

  let messages: ChatTurn[] = [];
  if (kind === "chat") {
    if (!Array.isArray(b.messages) || b.messages.length === 0) {
      return "Chat needs messages.";
    }
    if (b.messages.length > MAX_TURNS) return "Conversation too long.";
    for (const [i, m] of b.messages.entries()) {
      if (typeof m !== "object" || m === null) return "Bad message.";
      const { role, text } = m as Record<string, unknown>;
      const expected = i % 2 === 0 ? "user" : "assistant";
      if (role !== expected) return "Messages must alternate, user first.";
      if (typeof text !== "string" || text.trim() === "") {
        return "Empty message.";
      }
      if (text.length > MAX_TURN_CHARS) return "Message too long.";
    }
    if (b.messages.length % 2 === 0) return "Last message must be the user's.";
    messages = b.messages as ChatTurn[];
  }

  return {
    kind,
    eventKey: b.eventKey,
    payload: b.payload as Record<string, unknown>,
    messages,
  };
}

/** JSON with object keys sorted, so equal data always hashes the same. */
export function canonicalJson(value: unknown): string {
  if (Array.isArray(value)) return `[${value.map(canonicalJson).join(",")}]`;
  if (value !== null && typeof value === "object") {
    const obj = value as Record<string, unknown>;
    return `{${
      Object.keys(obj).sort().filter((k) => obj[k] !== undefined).map((k) =>
        `${JSON.stringify(k)}:${canonicalJson(obj[k])}`
      ).join(",")
    }}`;
  }
  return JSON.stringify(value);
}

export async function cacheKey(req: GenerateRequest): Promise<string> {
  const text = canonicalJson({
    v: PROMPT_VERSION,
    model: MODEL,
    kind: req.kind,
    eventKey: req.eventKey,
    payload: req.payload,
  });
  const digest = await crypto.subtle.digest(
    "SHA-256",
    new TextEncoder().encode(text),
  );
  return Array.from(new Uint8Array(digest))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

// ── Cost ─────────────────────────────────────────────────────────────────────

interface Price {
  input: number;
  cacheWrite: number;
  cacheRead: number;
  output: number;
}

/**
 * USD per million tokens, from platform.claude.com/docs/en/about-claude/pricing
 * (checked 2026-11-20). Cache writes are the 5-minute rate. Sonnet 5 is listed
 * because the refusal fallback can route a request there; its cache rates use
 * the standard 1.25x / 0.1x multipliers.
 */
export const PRICES: Record<string, Price> = {
  "claude-sonnet-5-5": {
    input: 2,
    cacheWrite: 2.5,
    cacheRead: 0.1,
    output: 10,
  },
  "claude-sonnet-5": { input: 2, cacheWrite: 2.5, cacheRead: 0.2, output: 10 },
  "claude-opus-5-5": { input: 4, cacheWrite: 5, cacheRead: 0.2, output: 20 },
};

/** Charged for a model missing from [PRICES]: the dearest one, to be safe. */
const FALLBACK_PRICE = PRICES["claude-opus-5-5"];

export interface Usage {
  input_tokens: number;
  output_tokens: number;
  cache_creation_input_tokens?: number | null;
  cache_read_input_tokens?: number | null;
}

/**
 * Dollar cost of one response. Thinking tokens are already inside
 * `output_tokens`. When a fallback served the request, the dearer of the two
 * models' prices is used, so the budget errs on the side of over-counting.
 */
export function costUsd(usage: Usage, servedModel: string): number {
  const served = PRICES[servedModel] ?? FALLBACK_PRICE;
  const requested = PRICES[MODEL];
  const p: Price = {
    input: Math.max(served.input, requested.input),
    cacheWrite: Math.max(served.cacheWrite, requested.cacheWrite),
    cacheRead: Math.max(served.cacheRead, requested.cacheRead),
    output: Math.max(served.output, requested.output),
  };
  return (
    usage.input_tokens * p.input +
    (usage.cache_creation_input_tokens ?? 0) * p.cacheWrite +
    (usage.cache_read_input_tokens ?? 0) * p.cacheRead +
    usage.output_tokens * p.output
  ) / 1_000_000;
}

/** Per-kind generation settings. */
export function settingsFor(kind: Kind): {
  effort: "low" | "medium";
  maxTokens: number;
} {
  switch (kind) {
    case "team_summary":
      return { effort: "low", maxTokens: 4000 };
    case "picklist_review":
      return { effort: "low", maxTokens: 6000 };
    case "match_brief":
      return { effort: "medium", maxTokens: 8000 };
    case "chat":
      return { effort: "medium", maxTokens: 6000 };
  }
}
