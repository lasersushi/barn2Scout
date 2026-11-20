import { assert, assertEquals } from "jsr:@std/assert@1.0.13";

import {
  accessFor,
  cacheKey,
  canonicalJson,
  costUsd,
  type GenerateRequest,
  parseGenerate,
} from "./policy.ts";
import { systemPrompt } from "./prompts.ts";

const DOMAINS = ["priorypanther.com", "prioryca.org"];

Deno.test("scouters get team summaries only", () => {
  const a = accessFor("kid@priorypanther.com", {
    role: "scout",
    ai_access: false,
  }, DOMAINS);
  assertEquals(a.allowed, true);
  assertEquals(a.unlimited, false);
  assertEquals(a.kinds, ["team_summary"]);
});

Deno.test("AI role adds chat and briefs, unlimited, but no picklist", () => {
  const a = accessFor("kid@priorypanther.com", {
    role: "scout",
    ai_access: true,
  }, DOMAINS);
  assertEquals(a.unlimited, true);
  assertEquals(a.kinds, ["team_summary", "match_brief", "chat"]);
});

Deno.test("admins get everything, whatever their email domain", () => {
  for (const role of ["admin", "super_admin"]) {
    const a = accessFor(
      "mentor@gmail.com",
      { role, ai_access: false },
      DOMAINS,
    );
    assertEquals(a.allowed, true);
    assertEquals(a.unlimited, true);
    assertEquals(a.kinds, [
      "team_summary",
      "match_brief",
      "chat",
      "picklist_review",
    ]);
  }
});

Deno.test("outside accounts and missing profiles", () => {
  assertEquals(
    accessFor("x@gmail.com", { role: "scout", ai_access: true }, DOMAINS)
      .allowed,
    false,
  );
  const noProfile = accessFor("kid@PRIORYPANTHER.com", null, DOMAINS);
  assertEquals(noProfile.allowed, true);
  assertEquals(noProfile.kinds, ["team_summary"]);
});

Deno.test("parseGenerate validates kind, event and chat turns", () => {
  const ok = parseGenerate({
    kind: "team_summary",
    eventKey: "2026cacac",
    payload: { team: 254 },
  });
  assert(typeof ok !== "string");

  assertEquals(
    parseGenerate({ kind: "poem", eventKey: "2026cacac", payload: {} }),
    "Unknown kind.",
  );
  assertEquals(
    parseGenerate({ kind: "chat", eventKey: "nope", payload: {} }),
    "Bad eventKey.",
  );
  assertEquals(
    parseGenerate({ kind: "chat", eventKey: "2026cacac", payload: [] }),
    "payload must be an object.",
  );
  assertEquals(
    parseGenerate({
      kind: "chat",
      eventKey: "2026cacac",
      payload: {},
      messages: [],
    }),
    "Chat needs messages.",
  );
  assertEquals(
    parseGenerate({
      kind: "chat",
      eventKey: "2026cacac",
      payload: {},
      messages: [{ role: "user", text: "hi" }, {
        role: "assistant",
        text: "hello",
      }],
    }),
    "Last message must be the user's.",
  );
  assertEquals(
    parseGenerate({
      kind: "chat",
      eventKey: "2026cacac",
      payload: {},
      messages: [{ role: "assistant", text: "hi" }],
    }),
    "Messages must alternate, user first.",
  );
  const chat = parseGenerate({
    kind: "chat",
    eventKey: "2026cacac",
    payload: {},
    messages: [{ role: "user", text: "Who plays defense?" }],
  });
  assert(typeof chat !== "string");
  assertEquals(chat.messages.length, 1);
});

Deno.test("cache key ignores key order but not data", async () => {
  const base: GenerateRequest = {
    kind: "team_summary",
    eventKey: "2026cacac",
    payload: { team: 254, tba: { opr: 50, dpr: 10 } },
    messages: [],
  };
  const reordered = {
    ...base,
    payload: { tba: { dpr: 10, opr: 50 }, team: 254 },
  };
  const changed = {
    ...base,
    payload: { team: 254, tba: { opr: 51, dpr: 10 } },
  };
  assertEquals(await cacheKey(base), await cacheKey(reordered));
  assert((await cacheKey(base)) !== (await cacheKey(changed)));
  assertEquals(
    canonicalJson({ b: 1, a: [2, { d: 1, c: 2 }] }),
    '{"a":[2,{"c":2,"d":1}],"b":1}',
  );
});

Deno.test("cost matches the Sonnet 5.5 price card", () => {
  // 5K input, 1K output: 5000*2 + 1000*10 = 20,000 µ$ = $0.02
  assertEquals(
    costUsd({ input_tokens: 5000, output_tokens: 1000 }, "claude-sonnet-5-5"),
    0.02,
  );
  // Cache write 25K at $2.50, read 25K at $0.10.
  const c = costUsd({
    input_tokens: 0,
    output_tokens: 0,
    cache_creation_input_tokens: 25_000,
    cache_read_input_tokens: 25_000,
  }, "claude-sonnet-5-5");
  assertEquals(Math.round(c * 1e6), 65_000); // $0.0625 + $0.0025
  // An unknown served model is charged at the dearest known rate.
  assertEquals(
    costUsd({ input_tokens: 1_000_000, output_tokens: 0 }, "mystery"),
    4,
  );
});

Deno.test("every prompt carries the qualitative-only rule", () => {
  for (
    const kind of [
      "team_summary",
      "match_brief",
      "picklist_review",
      "chat",
    ] as const
  ) {
    const p = systemPrompt(kind);
    assert(p.includes("These are the only source for numbers"));
    assert(p.includes("don't average, total or rank teams from scout entries"));
  }
});
