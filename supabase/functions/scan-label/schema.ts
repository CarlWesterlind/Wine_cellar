import { z } from "zod";

export const WINE_TYPES = [
  "red",
  "white",
  "rose",
  "sparkling",
  "dessert",
  "fortified",
] as const;

export type WineType = (typeof WINE_TYPES)[number];

const CONFIDENCE = ["high", "medium", "low"] as const;

/** What Claude returns for a label photo. Field names match the app.
 *
 * `type` and `confidence` are plain strings here: the structured-output
 * schema can't enforce a list of values, so [sanitize] maps them instead of
 * letting an answer like "Rosé" fail the whole scan. */
export const LabelScanSchema = z.object({
  is_wine_label: z.boolean(),
  confidence: z.string().describe("One of: high, medium, low"),
  name: z.string().nullable(),
  producer: z.string().nullable(),
  vintage: z.number().int().nullable(),
  type: z
    .string()
    .nullable()
    .describe(`One of: ${WINE_TYPES.join(", ")}`),
  country: z.string().nullable(),
  region: z.string().nullable(),
  grapes: z.array(z.string()),
  drink_from: z.number().int().nullable(),
  drink_until: z.number().int().nullable(),
  sommelier: z
    .object({
      tasting_profile: z.string(),
      food_pairings: z.array(z.string()),
      serving_temperature: z.string(),
      decanting: z.string(),
    })
    .nullable(),
  producer_info: z.string().nullable(),
});

/** The raw answer from Claude. */
export type RawLabelScan = z.infer<typeof LabelScanSchema>;

/** The answer after [sanitize], as sent to the app. */
export type LabelScan = Omit<RawLabelScan, "type" | "confidence"> & {
  type: WineType | null;
  confidence: (typeof CONFIDENCE)[number];
};

/** "Rosé", " RED " and "rose" all become a known wine type, or null. */
function wineType(value: string | null): WineType | null {
  const plain = value?.normalize("NFD").replace(/[\u0300-\u036f]/g, "")
    .trim().toLowerCase();
  return WINE_TYPES.find((type) => type === plain) ?? null;
}

export const LANGUAGES = {
  sv: "Swedish",
  da: "Danish",
  nb: "Norwegian Bokmål",
  en: "English",
} as const;

export type Language = keyof typeof LANGUAGES;

export const MEDIA_TYPES = ["image/jpeg", "image/png", "image/webp"] as const;

export type MediaType = (typeof MEDIA_TYPES)[number];

export interface ScanRequest {
  front: string;
  back?: string;
  mediaType: MediaType;
  language: Language;
}

/** Cleans up the model's answer: blank text becomes null, impossible years
 * are dropped, and grapes are trimmed and de-duplicated. */
export function sanitize(scan: RawLabelScan, now: Date): LabelScan {
  const text = (value: string | null) => {
    const trimmed = value?.trim();
    return trimmed ? trimmed : null;
  };
  const thisYear = now.getUTCFullYear();
  const year = (value: number | null, min: number, max: number) =>
    value !== null && value >= min && value <= max ? value : null;

  const vintage = year(scan.vintage, 1800, thisYear);
  let drinkFrom = year(scan.drink_from, 1800, thisYear + 100);
  let drinkUntil = year(scan.drink_until, 1800, thisYear + 100);
  if (drinkFrom !== null && drinkUntil !== null && drinkFrom > drinkUntil) {
    drinkFrom = null;
    drinkUntil = null;
  }

  const grapes = [
    ...new Set(scan.grapes.map((g) => g.trim()).filter((g) => g.length > 0)),
  ];

  const sommelier = scan.sommelier && {
    tasting_profile: scan.sommelier.tasting_profile.trim(),
    food_pairings: scan.sommelier.food_pairings
      .map((f) => f.trim())
      .filter((f) => f.length > 0),
    serving_temperature: scan.sommelier.serving_temperature.trim(),
    decanting: scan.sommelier.decanting.trim(),
  };

  const confidence = scan.confidence.trim().toLowerCase();

  return {
    ...scan,
    type: wineType(scan.type),
    confidence: CONFIDENCE.find((c) => c === confidence) ?? "low",
    name: text(scan.name),
    producer: text(scan.producer),
    vintage,
    country: text(scan.country),
    region: text(scan.region),
    grapes,
    drink_from: drinkFrom,
    drink_until: drinkUntil,
    sommelier: sommelier && sommelier.tasting_profile ? sommelier : null,
    producer_info: text(scan.producer_info),
  };
}
