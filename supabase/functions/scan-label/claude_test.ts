import { assertEquals, assertStringIncludes } from "@std/assert";
import type Anthropic from "@anthropic-ai/sdk";

import { createAnalyzer, MODEL } from "./claude.ts";
import type { RawLabelScan } from "./schema.ts";

const scan = { is_wine_label: true } as RawLabelScan;

/** A stand-in for the Anthropic client that records the request and
 * returns [response]. */
function fakeClient(response: Record<string, unknown>) {
  // deno-lint-ignore no-explicit-any
  const requests: any[] = [];
  const client = {
    beta: {
      messages: {
        parse: (params: Record<string, unknown>) => {
          requests.push(params);
          return Promise.resolve(response);
        },
      },
    },
  } as unknown as Anthropic;
  return { client, requests };
}

Deno.test("sends the photos, model and settings to Claude", async () => {
  const { client, requests } = fakeClient({
    stop_reason: "end_turn",
    parsed_output: scan,
  });
  const result = await createAnalyzer(client)({
    front: "RlJPTlQ=",
    back: "QkFDSw==",
    mediaType: "image/jpeg",
    language: "nb",
  });

  assertEquals(result, { kind: "ok", scan });
  const [request] = requests;
  assertEquals(request.model, MODEL);
  assertEquals(request.fallbacks, "default");
  assertEquals(request.betas, ["server-side-fallback-2026-07-01"]);
  assertEquals(request.output_config.effort, "medium");

  const content = request.messages[0].content;
  assertEquals(content[0].source.data, "RlJPTlQ=");
  assertEquals(content[1].source.data, "QkFDSw==");
  assertEquals(content[0].source.media_type, "image/jpeg");
  assertStringIncludes(content[2].text, "second the back label");
  assertStringIncludes(content[2].text, "Norwegian Bokmål");
});

Deno.test("works with only a front photo", async () => {
  const { client, requests } = fakeClient({
    stop_reason: "end_turn",
    parsed_output: scan,
  });
  await createAnalyzer(client)({
    front: "RlJPTlQ=",
    mediaType: "image/png",
    language: "sv",
  });
  const content = requests[0].messages[0].content;
  assertEquals(content.length, 2);
  assertStringIncludes(content[1].text, "The photo is the front label");
  assertStringIncludes(content[1].text, "Swedish");
});

for (
  const [description, response, kind] of [
    ["a refusal", { stop_reason: "refusal", parsed_output: null }, "refused"],
    [
      "a cut-off answer",
      { stop_reason: "max_tokens", parsed_output: scan },
      "failed",
    ],
    [
      "an unparsable answer",
      { stop_reason: "end_turn", parsed_output: null },
      "failed",
    ],
  ] as const
) {
  Deno.test(`reports ${description} as ${kind}`, async () => {
    const { client } = fakeClient(response);
    const result = await createAnalyzer(client)({
      front: "RlJPTlQ=",
      mediaType: "image/jpeg",
      language: "en",
    });
    assertEquals(result.kind, kind);
  });
}
