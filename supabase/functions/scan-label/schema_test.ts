import { assertEquals } from "@std/assert";

import { type RawLabelScan, sanitize } from "./schema.ts";

const NOW = new Date("2026-10-29T12:00:00Z");

const base: RawLabelScan = {
  is_wine_label: true,
  confidence: "medium",
  name: "Chablis",
  producer: null,
  vintage: 2022,
  type: "white",
  country: "France",
  region: "Bourgogne",
  grapes: ["Chardonnay"],
  drink_from: 2024,
  drink_until: 2030,
  sommelier: null,
  producer_info: null,
};

Deno.test("blank text becomes null", () => {
  const scan = sanitize(
    {
      ...base,
      name: "  ",
      producer: "",
      region: " Chablis ",
      producer_info: " ",
    },
    NOW,
  );
  assertEquals(scan.name, null);
  assertEquals(scan.producer, null);
  assertEquals(scan.region, "Chablis");
  assertEquals(scan.producer_info, null);
});

Deno.test("a vintage in the future or before 1800 is dropped", () => {
  assertEquals(sanitize({ ...base, vintage: 2027 }, NOW).vintage, null);
  assertEquals(sanitize({ ...base, vintage: 1799 }, NOW).vintage, null);
  assertEquals(sanitize({ ...base, vintage: 2026 }, NOW).vintage, 2026);
});

Deno.test("a drinking window that ends before it starts is dropped", () => {
  const scan = sanitize({ ...base, drink_from: 2035, drink_until: 2030 }, NOW);
  assertEquals([scan.drink_from, scan.drink_until], [null, null]);
});

Deno.test("an open-ended drinking window is kept", () => {
  const scan = sanitize({ ...base, drink_from: 2030, drink_until: null }, NOW);
  assertEquals([scan.drink_from, scan.drink_until], [2030, null]);
});

Deno.test("grapes are trimmed and de-duplicated", () => {
  const scan = sanitize(
    { ...base, grapes: [" Pinot Noir", "Pinot Noir ", "", "Chardonnay"] },
    NOW,
  );
  assertEquals(scan.grapes, ["Pinot Noir", "Chardonnay"]);
});

Deno.test("sommelier info without a tasting profile is dropped", () => {
  const scan = sanitize({
    ...base,
    sommelier: {
      tasting_profile: " ",
      food_pairings: ["Ostron"],
      serving_temperature: "10 °C",
      decanting: "Nej",
    },
  }, NOW);
  assertEquals(scan.sommelier, null);
});

Deno.test("empty food pairings are removed", () => {
  const scan = sanitize({
    ...base,
    sommelier: {
      tasting_profile: "Mineraliskt.",
      food_pairings: ["Ostron", " ", "Sushi "],
      serving_temperature: "10 °C",
      decanting: "Nej",
    },
  }, NOW);
  assertEquals(scan.sommelier?.food_pairings, ["Ostron", "Sushi"]);
});

Deno.test("wine types are matched without case or accents", () => {
  for (
    const [raw, type] of [
      ["Rosé", "rose"],
      [" RED ", "red"],
      ["sparkling", "sparkling"],
      ["orange", null],
      [null, null],
    ] as const
  ) {
    assertEquals(sanitize({ ...base, type: raw }, NOW).type, type, `${raw}`);
  }
});

Deno.test("unknown confidence becomes low", () => {
  assertEquals(
    sanitize({ ...base, confidence: "High" }, NOW).confidence,
    "high",
  );
  assertEquals(
    sanitize({ ...base, confidence: "very" }, NOW).confidence,
    "low",
  );
});
