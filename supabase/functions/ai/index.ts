// `ai` Edge Function: the only place Barn2Scout talks to Claude.
//
// POST {action: "access"}   → JSON: what this user may do, uses left today.
// POST {action: "generate", kind, eventKey, payload, messages?}
//                           → NDJSON stream of {type: "delta" | "done" | "error"}.
//
// The Anthropic key lives in the function's secrets (ANTHROPIC_API_KEY), never
// in the app. Supabase verifies the caller's JWT before this code runs.

import Anthropic from "npm:@anthropic-ai/sdk@1.5.0";
import { createClient } from "npm:@supabase/supabase-js@2.119.0";

import {
  type Access,
  accessFor,
  CACHEABLE,
  cacheKey,
  costUsd,
  DEFAULT_DAILY_LIMIT,
  DEFAULT_MONTH_CAP_USD,
  DEFAULT_YEAR_CAP_USD,
  type GenerateRequest,
  MAX_BODY_BYTES,
  MODEL,
  parseGenerate,
  settingsFor,
} from "./policy.ts";
import { systemPrompt } from "./prompts.ts";

const env = (name: string, fallback?: string) => {
  const v = Deno.env.get(name);
  if (v !== undefined && v !== "") return v;
  if (fallback !== undefined) return fallback;
  throw new Error(`Missing env ${name}`);
};

const DAILY_LIMIT = Number(env("AI_DAILY_LIMIT", String(DEFAULT_DAILY_LIMIT)));
const MONTH_CAP = Number(
  env("AI_MONTH_CAP_USD", String(DEFAULT_MONTH_CAP_USD)),
);
const YEAR_CAP = Number(env("AI_YEAR_CAP_USD", String(DEFAULT_YEAR_CAP_USD)));
const ALLOWED_DOMAINS = env(
  "AI_ALLOWED_EMAIL_DOMAINS",
  "priorypanther.com,prioryca.org",
)
  .split(",").map((d) => d.trim().toLowerCase()).filter(Boolean);

const db = createClient(env("SUPABASE_URL"), env("SUPABASE_SERVICE_ROLE_KEY"), {
  auth: { persistSession: false, autoRefreshToken: false },
});
const anthropic = new Anthropic({ apiKey: env("ANTHROPIC_API_KEY") });

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function json(status: number, body: unknown): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS, "Content-Type": "application/json" },
  });
}

const fail = (status: number, code: string, message: string) =>
  json(status, { error: { code, message } });

/** Generations this user has left today, or null when unlimited. */
async function remainingToday(userId: string, access: Access) {
  if (access.unlimited) return null;
  const today = new Date().toISOString().slice(0, 10);
  const { data } = await db.from("ai_usage").select("requests")
    .eq("user_id", userId).eq("day", today).maybeSingle();
  return Math.max(DAILY_LIMIT - (data?.requests ?? 0), 0);
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  if (req.method !== "POST") return fail(405, "bad_request", "POST only.");

  // ── Who is asking ──────────────────────────────────────────────────────────
  const jwt = (req.headers.get("Authorization") ?? "").replace(
    /^Bearer\s+/i,
    "",
  );
  const { data: userData, error: authError } = await db.auth.getUser(jwt);
  const user = userData?.user;
  if (authError || !user) return fail(401, "unauthorized", "Sign in again.");

  const { data: profile } = await db.from("profiles")
    .select("role, ai_access").eq("id", user.id).maybeSingle();
  const access = accessFor(user.email, profile, ALLOWED_DOMAINS);
  if (!access.allowed) {
    return fail(403, "forbidden", "This account can't use AI features.");
  }

  // ── Body ───────────────────────────────────────────────────────────────────
  const raw = await req.text();
  if (raw.length > MAX_BODY_BYTES) {
    return fail(413, "bad_request", "Request too large.");
  }
  let body: Record<string, unknown>;
  try {
    body = JSON.parse(raw);
  } catch {
    return fail(400, "bad_request", "Body must be JSON.");
  }

  if (body.action === "access") {
    return json(200, {
      unlimited: access.unlimited,
      isAdmin: access.isAdmin,
      kinds: access.kinds,
      dailyLimit: access.unlimited ? null : DAILY_LIMIT,
      remainingToday: await remainingToday(user.id, access),
    });
  }
  if (body.action !== "generate") {
    return fail(400, "bad_request", "Unknown action.");
  }

  const parsed = parseGenerate(body);
  if (typeof parsed === "string") return fail(400, "bad_request", parsed);
  if (!access.kinds.includes(parsed.kind)) {
    return fail(403, "forbidden", "Your account doesn't have this AI feature.");
  }

  // ── Shared cache: free, and doesn't count against the daily limit ──────────
  const key = CACHEABLE.has(parsed.kind) ? await cacheKey(parsed) : null;
  if (key) {
    const { data: hit } = await db.from("ai_cache").select("content")
      .eq("cache_key", key).maybeSingle();
    if (hit) {
      return ndjson([
        { type: "delta", text: hit.content },
        {
          type: "done",
          cached: true,
          remainingToday: await remainingToday(user.id, access),
        },
      ]);
    }
  }

  // ── Budget ─────────────────────────────────────────────────────────────────
  const { data: verdict, error: rpcError } = await db.rpc("ai_try_consume", {
    p_user: user.id,
    p_daily_limit: access.unlimited ? null : DAILY_LIMIT,
    p_month_cap: MONTH_CAP,
    p_year_cap: YEAR_CAP,
  });
  if (rpcError) return fail(500, "server", "Couldn't check the AI budget.");
  if (verdict === "daily_limit") {
    return fail(
      429,
      "daily_limit",
      `You've used today's ${DAILY_LIMIT} AI generations.`,
    );
  }
  if (verdict === "budget_reached") {
    return fail(
      429,
      "budget_reached",
      "The team's AI budget is used up. Ask a mentor.",
    );
  }

  return new Response(generate(parsed, user.id, access, key), {
    headers: { ...CORS, "Content-Type": "application/x-ndjson" },
  });
});

/** A finished NDJSON response from fixed events. */
function ndjson(events: unknown[]): Response {
  const text = events.map((e) => JSON.stringify(e)).join("\n") + "\n";
  return new Response(text, {
    headers: { ...CORS, "Content-Type": "application/x-ndjson" },
  });
}

/** Streams Claude's answer as NDJSON, then records cost and caches it. */
function generate(
  req: GenerateRequest,
  userId: string,
  access: Access,
  key: string | null,
): ReadableStream<Uint8Array> {
  const encoder = new TextEncoder();
  let open = true;

  return new ReadableStream({
    async start(controller) {
      const send = (event: unknown) => {
        if (!open) return; // client went away; keep generating so it caches
        try {
          controller.enqueue(encoder.encode(JSON.stringify(event) + "\n"));
        } catch {
          open = false;
        }
      };

      const { effort, maxTokens } = settingsFor(req.kind);
      const data = JSON.stringify(req.payload);
      const isChat = req.kind === "chat";

      try {
        const stream = anthropic.beta.messages.stream({
          model: MODEL,
          max_tokens: maxTokens,
          output_config: { effort },
          // Re-run a policy decline on the server's default fallback model.
          betas: ["server-side-fallback-2026-07-01"],
          fallbacks: "default",
          // Chat re-sends the same event data every turn: cache the prefix so
          // follow-ups pay the cache-read rate.
          ...(isChat ? { cache_control: { type: "ephemeral" as const } } : {}),
          system: [
            { type: "text", text: systemPrompt(req.kind) },
            {
              type: "text",
              text: `Event ${req.eventKey} data (JSON):\n${data}`,
            },
          ],
          messages: isChat
            ? req.messages.map((m) => ({ role: m.role, content: m.text }))
            : [{ role: "user", content: "Write it now from the data above." }],
        });

        let text = "";
        for await (const event of stream) {
          if (
            event.type === "content_block_delta" &&
            event.delta.type === "text_delta"
          ) {
            text += event.delta.text;
            send({ type: "delta", text: event.delta.text });
          }
        }
        const final = await stream.finalMessage();
        await db.rpc("ai_record_cost", {
          p_user: userId,
          p_cost: costUsd(final.usage, final.model),
          p_refund: false,
        });

        if (final.stop_reason === "refusal") {
          send({
            type: "error",
            code: "refused",
            message: "The AI declined this request.",
          });
        } else {
          const truncated = final.stop_reason === "max_tokens";
          if (key && !truncated && text.trim() !== "") {
            await db.from("ai_cache").upsert({
              cache_key: key,
              kind: req.kind,
              event_key: req.eventKey,
              model: final.model,
              content: text,
            });
          }
          send({
            type: "done",
            cached: false,
            truncated,
            remainingToday: await remainingToday(userId, access),
          });
        }
      } catch (e) {
        // Nothing usable came back: give the request slot back.
        await db.rpc("ai_record_cost", {
          p_user: userId,
          p_cost: 0,
          p_refund: true,
        });
        const status = e instanceof Anthropic.APIError ? e.status : undefined;
        console.error("Claude call failed", status, e);
        send({
          type: "error",
          code: "server",
          message: status === 429 || status === 529
            ? "The AI service is busy. Try again in a minute."
            : "The AI service had a problem. Try again.",
        });
      } finally {
        if (open) {
          try {
            controller.close();
          } catch {
            // already closed by the client
          }
        }
      }
    },
    cancel() {
      open = false;
    },
  });
}
