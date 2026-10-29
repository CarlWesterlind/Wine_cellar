import { assertEquals, assertFalse } from "@std/assert";

import type { AnalyzeResult } from "./claude.ts";
import { createHandler, type Deps, MAX_IMAGE_BYTES } from "./handler.ts";
import type { LabelScan, ScanRequest } from "./schema.ts";

const NOW = new Date("2026-10-29T12:00:00Z");
const SMALL_IMAGE = btoa("fake jpeg bytes!"); // Valid base64.

const barolo: LabelScan = {
  is_wine_label: true,
  confidence: "high",
  name: "Barolo Cannubi",
  producer: "Paolo Scavino",
  vintage: 2019,
  type: "red",
  country: "Italia",
  region: "Piemonte",
  grapes: ["Nebbiolo"],
  drink_from: 2027,
  drink_until: 2040,
  sommelier: {
    tasting_profile: "Körsbär, ros och tjära.",
    food_pairings: ["Tryffelrisotto", "Viltgryta"],
    serving_temperature: "17–18 °C",
    decanting: "Dekantera 1–2 timmar.",
  },
  producer_info: "Familjeägd producent i Castiglione Falletto.",
};

/** A handler with fake dependencies, and a record of what it did. */
function setup(overrides: Partial<Deps> & {
  signedIn?: boolean;
  scansToday?: number;
  result?: AnalyzeResult | Error;
} = {}) {
  const calls = { recorded: 0, analyzed: [] as ScanRequest[], logged: 0 };
  const deps: Deps = {
    signedInUser: () =>
      Promise.resolve(
        overrides.signedIn === false ? null : {
          countSince: () => Promise.resolve(overrides.scansToday ?? 0),
          record: () => {
            calls.recorded++;
            return Promise.resolve();
          },
        },
      ),
    analyze: (request) => {
      calls.analyzed.push(request);
      const result = overrides.result ?? { kind: "ok", scan: barolo };
      return result instanceof Error
        ? Promise.reject(result)
        : Promise.resolve(result);
    },
    dailyLimit: 50,
    now: () => NOW,
    log: () => calls.logged++,
    ...overrides,
  };
  return { handle: createHandler(deps), calls };
}

function post(body: unknown, init: RequestInit = {}) {
  return new Request("http://localhost/scan-label", {
    method: "POST",
    body: typeof body === "string" ? body : JSON.stringify(body),
    ...init,
  });
}

const validBody = {
  front: SMALL_IMAGE,
  mediaType: "image/jpeg",
  language: "sv",
};

Deno.test("answers the browser's CORS preflight", async () => {
  const { handle } = setup();
  const response = await handle(
    new Request("http://localhost/scan-label", { method: "OPTIONS" }),
  );
  assertEquals(response.status, 200);
  assertEquals(response.headers.get("Access-Control-Allow-Origin"), "*");
});

Deno.test("rejects requests without a valid login", async () => {
  const { handle, calls } = setup({ signedIn: false });
  const response = await handle(post(validBody));
  assertEquals(response.status, 401);
  assertEquals(await response.json(), { error: "unauthorized" });
  assertEquals(calls.analyzed.length, 0);
});

Deno.test("rejects other methods than POST", async () => {
  const { handle } = setup();
  const response = await handle(
    new Request("http://localhost/scan-label", { method: "GET" }),
  );
  assertEquals(response.status, 405);
});

for (
  const [description, body] of [
    ["broken JSON", "{not json"],
    ["no front photo", { ...validBody, front: undefined }],
    ["front photo that is not base64", { ...validBody, front: "not base64!" }],
    ["empty front photo", { ...validBody, front: "" }],
    ["back photo that is not base64", { ...validBody, back: "%%%%" }],
    ["unsupported image type", { ...validBody, mediaType: "image/gif" }],
    ["unsupported language", { ...validBody, language: "fr" }],
    ["no language", { ...validBody, language: undefined }],
  ] as const
) {
  Deno.test(`rejects a request with ${description}`, async () => {
    const { handle, calls } = setup();
    const response = await handle(post(body));
    assertEquals(response.status, 400);
    assertEquals(await response.json(), { error: "bad_request" });
    assertEquals(calls.analyzed.length, 0);
    assertEquals(calls.recorded, 0);
  });
}

Deno.test("rejects photos over 5 MB", async () => {
  const { handle, calls } = setup();
  // Valid base64 that decodes to one byte more than allowed.
  const big = "A".repeat(Math.ceil((MAX_IMAGE_BYTES + 1) / 3) * 4);
  const response = await handle(post({ ...validBody, back: big }));
  assertEquals(response.status, 413);
  assertEquals(await response.json(), { error: "image_too_large" });
  assertEquals(calls.recorded, 0);
});

Deno.test("stops at the daily limit without calling Claude", async () => {
  const { handle, calls } = setup({ scansToday: 50 });
  const response = await handle(post(validBody));
  assertEquals(response.status, 429);
  assertEquals(await response.json(), { error: "daily_limit", limit: 50 });
  assertEquals(calls.analyzed.length, 0);
  assertEquals(calls.recorded, 0);
});

Deno.test("the last scan under the limit is allowed", async () => {
  const { handle } = setup({ scansToday: 49 });
  const response = await handle(post(validBody));
  assertEquals(response.status, 200);
});

Deno.test("counts the scan before calling Claude", async () => {
  const order: string[] = [];
  const { handle } = setup({
    signedInUser: () =>
      Promise.resolve({
        countSince: () => Promise.resolve(0),
        record: () => {
          order.push("record");
          return Promise.resolve();
        },
      }),
    analyze: () => {
      order.push("analyze");
      return Promise.resolve({ kind: "ok", scan: barolo });
    },
  });
  await handle(post(validBody));
  assertEquals(order, ["record", "analyze"]);
});

Deno.test("sends both photos and the language to Claude", async () => {
  const { handle, calls } = setup();
  const back = btoa("back label bytes");
  await handle(post({ ...validBody, back, mediaType: "image/png" }));
  assertEquals(calls.analyzed, [
    { front: SMALL_IMAGE, back, mediaType: "image/png", language: "sv" },
  ]);
});

Deno.test("returns the cleaned-up scan", async () => {
  const { handle } = setup();
  const response = await handle(post(validBody));
  assertEquals(response.status, 200);
  assertEquals(await response.json(), { scan: barolo });
});

Deno.test("a photo that is not a wine label gets its own error", async () => {
  const { handle } = setup({
    result: { kind: "ok", scan: { ...barolo, is_wine_label: false } },
  });
  const response = await handle(post(validBody));
  assertEquals(response.status, 422);
  assertEquals(await response.json(), { error: "not_wine_label" });
});

for (const kind of ["refused", "failed"] as const) {
  Deno.test(`a ${kind} answer is reported as unreadable`, async () => {
    const { handle } = setup({ result: { kind } });
    const response = await handle(post(validBody));
    assertEquals(response.status, 422);
    assertEquals(await response.json(), { error: "unreadable" });
  });
}

Deno.test("errors are logged but never sent to the app", async () => {
  const { handle, calls } = setup({
    result: new Error("secret: API key sk-ant-123 is invalid"),
  });
  const response = await handle(post(validBody));
  assertEquals(response.status, 502);
  const text = await response.text();
  assertEquals(JSON.parse(text), { error: "ai_unavailable" });
  assertFalse(text.includes("sk-ant"));
  assertEquals(calls.logged, 1);
});

Deno.test("a failing scan log is reported, not crashed on", async () => {
  const { handle } = setup({
    signedInUser: () =>
      Promise.resolve({
        countSince: () => Promise.reject(new Error("db down")),
        record: () => Promise.resolve(),
      }),
  });
  const response = await handle(post(validBody));
  assertEquals(response.status, 502);
});
