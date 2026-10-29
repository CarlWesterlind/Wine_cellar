import type { Analyzer } from "./claude.ts";
import {
  type Language,
  LANGUAGES,
  MEDIA_TYPES,
  type MediaType,
  sanitize,
  type ScanRequest,
} from "./schema.ts";

/** Largest photo accepted, in bytes. The Claude API allows 5 MB per image. */
export const MAX_IMAGE_BYTES = 5 * 1024 * 1024;

/** The scan log of one signed-in user. */
export interface UserScans {
  /** How many scans the user has started since [since]. */
  countSince(since: Date): Promise<number>;
  record(): Promise<void>;
}

export interface Deps {
  /** The scan log of the user who sent [request], or null if the request
   * has no valid login. Created per request, so concurrent requests never
   * share state. */
  signedInUser(request: Request): Promise<UserScans | null>;
  analyze: Analyzer;
  dailyLimit: number;
  now(): Date;
  log(message: string, error?: unknown): void;
}

/** Error codes the app turns into messages in the user's language. */
export type ErrorCode =
  | "bad_request"
  | "image_too_large"
  | "unauthorized"
  | "daily_limit"
  | "not_wine_label"
  | "unreadable"
  | "ai_unavailable";

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function json(status: number, body: unknown): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS_HEADERS, "Content-Type": "application/json" },
  });
}

function error(status: number, code: ErrorCode, extra: object = {}) {
  return json(status, { error: code, ...extra });
}

/** Decoded size of a base64 string, or null if it isn't valid base64. */
function base64Bytes(value: unknown): number | null {
  if (typeof value !== "string" || value.length === 0) return null;
  if (!/^[A-Za-z0-9+/]+={0,2}$/.test(value) || value.length % 4 !== 0) {
    return null;
  }
  const padding = value.endsWith("==") ? 2 : value.endsWith("=") ? 1 : 0;
  return (value.length / 4) * 3 - padding;
}

type Parsed = { ok: true; request: ScanRequest } | {
  ok: false;
  response: Response;
};

function parseBody(body: unknown): Parsed {
  const bad = (code: ErrorCode = "bad_request"): Parsed => ({
    ok: false,
    response: error(code === "image_too_large" ? 413 : 400, code),
  });
  if (typeof body !== "object" || body === null) return bad();
  const { front, back, mediaType, language } = body as Record<string, unknown>;

  for (
    const image of back === undefined || back === null ? [front] : [front, back]
  ) {
    const size = base64Bytes(image);
    if (size === null) return bad();
    if (size > MAX_IMAGE_BYTES) return bad("image_too_large");
  }
  if (!MEDIA_TYPES.includes(mediaType as MediaType)) return bad();
  if (typeof language !== "string" || !(language in LANGUAGES)) return bad();

  return {
    ok: true,
    request: {
      front: front as string,
      back: (back as string | null | undefined) ?? undefined,
      mediaType: mediaType as MediaType,
      language: language as Language,
    },
  };
}

/** Handles POST /scan-label: checks the login, the request and the daily
 * limit, then asks Claude to read the label. */
export function createHandler(
  deps: Deps,
): (request: Request) => Promise<Response> {
  return async (request) => {
    if (request.method === "OPTIONS") {
      return new Response("ok", { headers: CORS_HEADERS });
    }
    if (request.method !== "POST") return error(405, "bad_request");

    const user = await deps.signedInUser(request);
    if (user === null) return error(401, "unauthorized");

    let body: unknown;
    try {
      body = await request.json();
    } catch {
      return error(400, "bad_request");
    }
    const parsed = parseBody(body);
    if (!parsed.ok) return parsed.response;

    try {
      const since = new Date(deps.now().getTime() - 24 * 60 * 60 * 1000);
      const used = await user.countSince(since);
      if (used >= deps.dailyLimit) {
        return error(429, "daily_limit", { limit: deps.dailyLimit });
      }
      // Counted before calling Claude, so failed attempts count too.
      await user.record();

      const result = await deps.analyze(parsed.request);
      switch (result.kind) {
        case "refused":
        case "failed":
          return error(422, "unreadable");
        case "ok": {
          if (!result.scan.is_wine_label) return error(422, "not_wine_label");
          return json(200, { scan: sanitize(result.scan, deps.now()) });
        }
      }
    } catch (e) {
      // Details go to the function log only, never to the app.
      deps.log("scan-label failed", e);
      return error(502, "ai_unavailable");
    }
  };
}
