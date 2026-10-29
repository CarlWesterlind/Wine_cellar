// Supabase Edge Function: reads a wine label photo with Claude.
//
// Deploy:  supabase functions deploy scan-label
// Secret:  supabase secrets set ANTHROPIC_API_KEY=sk-ant-...
import Anthropic from "@anthropic-ai/sdk";
import { createClient } from "@supabase/supabase-js";

import { createAnalyzer } from "./claude.ts";
import { createHandler } from "./handler.ts";

const DAILY_LIMIT = 50;

const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const supabaseKey = Deno.env.get("SUPABASE_ANON_KEY")!;
const anthropic = new Anthropic({ apiKey: Deno.env.get("ANTHROPIC_API_KEY") });

const handler = createHandler({
  async signedInUser(request) {
    // Acts as the user who sent the request, so row level security limits
    // it to their own rows.
    const db = createClient(supabaseUrl, supabaseKey, {
      global: {
        headers: { Authorization: request.headers.get("Authorization") ?? "" },
      },
      auth: { persistSession: false },
    });
    const { data, error } = await db.auth.getUser();
    if (error || !data.user) return null;

    return {
      async countSince(since) {
        const { count, error } = await db
          .from("label_scans")
          .select("*", { count: "exact", head: true })
          .gte("created_at", since.toISOString());
        if (error) throw error;
        return count ?? 0;
      },
      async record() {
        const { error } = await db.from("label_scans").insert({});
        if (error) throw error;
      },
    };
  },
  analyze: createAnalyzer(anthropic),
  dailyLimit: DAILY_LIMIT,
  now: () => new Date(),
  log: (message, error) => console.error(message, error),
});

Deno.serve(handler);
