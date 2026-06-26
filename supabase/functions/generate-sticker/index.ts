// generate-sticker
// ----------------------------------------------------------------------------
// 1. Authenticates the caller via JWT.
// 2. Validates input and resolves a preset to a concrete style descriptor.
// 3. Atomically deducts credits + creates a pending sticker_generations row
//    via the SECURITY DEFINER RPC `deduct_credit_for_sticker`.
// 4. Calls OpenRouter `sourceful/riverflow-v2-fast` (modalities: ["image"]).
// 5. Uploads the generated image to the private `stickers` bucket.
// 6. Updates the sticker row with image path + status='success' and returns
//    a short-lived signed URL.
// On any post-RPC failure, calls `refund_failed_sticker` to restore credits.
// ----------------------------------------------------------------------------

import { createClient, SupabaseClient } from "@supabase/supabase-js";

const SUPABASE_URL          = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_ANON_KEY     = Deno.env.get("SUPABASE_ANON_KEY")!;
const SUPABASE_SERVICE_ROLE = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const OPENROUTER_API_KEY    = Deno.env.get("OPENROUTER_API_KEY")!;

const STICKER_COST       = 1;
const STORAGE_BUCKET     = "stickers";
const SIGNED_URL_TTL_SEC = 60 * 60; // 1 hour
const MAX_PROMPT_CHARS   = 200;

// Preset id -> style descriptor injected into the final prompt.
const PRESETS: Record<string, string> = {
  kawaii:        "kawaii cute pastel chibi cartoon",
  pixel_art:     "16-bit pixel art, crisp pixels, limited palette",
  vector_flat:   "flat vector illustration, bold outlines, solid fills",
  chibi_3d:      "3d chibi render, soft studio lighting, glossy",
  retro_sticker: "1990s retro sticker, halftone shading, vibrant",
};

const cors = {
  "Access-Control-Allow-Origin":  "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...cors, "content-type": "application/json" },
  });
}

function buildFinalPrompt(style: string, userInput: string): string {
  return [
    "die-cut sticker",
    "pure white background",
    "thick white border",
    "centered subject",
    "no shadow",
    "high contrast",
    `${style} style`,
    `Subject: ${userInput}`,
  ].join(", ");
}

interface OpenRouterImageResponse {
  choices?: Array<{
    message?: {
      images?: Array<{ image_url?: { url?: string } | string }>;
      content?: string;
    };
  }>;
}

async function callOpenRouter(prompt: string): Promise<{ bytes: Uint8Array; contentType: string }> {
  const res = await fetch("https://openrouter.ai/api/v1/chat/completions", {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${OPENROUTER_API_KEY}`,
      "Content-Type":  "application/json",
      "HTTP-Referer":  "https://bikinstiker.app",
      "X-Title":       "BikinStiker",
    },
    body: JSON.stringify({
      model: "sourceful/riverflow-v2-fast",
      modalities: ["image"],
      messages: [{ role: "user", content: prompt }],
    }),
  });

  if (!res.ok) {
    const text = await res.text();
    throw new Error(`OpenRouter error ${res.status}: ${text}`);
  }

  const data = (await res.json()) as OpenRouterImageResponse;
  const first = data.choices?.[0]?.message?.images?.[0];
  const url = typeof first === "string"
    ? first
    : first?.image_url && (typeof first.image_url === "string" ? first.image_url : first.image_url.url);

  if (!url) {
    throw new Error("OpenRouter response did not contain an image");
  }

  // The image may be a data URL (base64) or an https URL — handle both.
  if (url.startsWith("data:")) {
    const [meta, b64] = url.split(",", 2);
    const contentType = meta.replace(/^data:/, "").replace(/;base64$/, "") || "image/png";
    const bin = atob(b64);
    const bytes = new Uint8Array(bin.length);
    for (let i = 0; i < bin.length; i++) bytes[i] = bin.charCodeAt(i);
    return { bytes, contentType };
  }

  const imgRes = await fetch(url);
  if (!imgRes.ok) throw new Error(`Failed to fetch generated image: ${imgRes.status}`);
  const contentType = imgRes.headers.get("content-type") ?? "image/png";
  const bytes = new Uint8Array(await imgRes.arrayBuffer());
  return { bytes, contentType };
}

async function refund(service: SupabaseClient, stickerId: string) {
  try {
    await service.rpc("refund_failed_sticker", { p_sticker_id: stickerId });
  } catch (e) {
    console.error("Refund failed", e);
  }
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST")    return json({ error: "Method not allowed" }, 405);

  const authHeader = req.headers.get("Authorization") ?? "";
  if (!authHeader.startsWith("Bearer ")) {
    return json({ error: "Missing bearer token" }, 401);
  }

  // User-scoped client — RLS + auth.uid() apply, so RPC sees the real caller.
  const userClient = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    global: { headers: { Authorization: authHeader } },
    auth:   { persistSession: false, autoRefreshToken: false },
  });

  const { data: userRes, error: userErr } = await userClient.auth.getUser();
  if (userErr || !userRes?.user) {
    return json({ error: "Unauthorized" }, 401);
  }
  const userId = userRes.user.id;

  // Service-role client — used only for storage + status updates + refunds.
  const service = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  // ------------------- validate input -------------------
  let body: { userInput?: unknown; presetId?: unknown };
  try {
    body = await req.json();
  } catch {
    return json({ error: "Invalid JSON body" }, 400);
  }

  const userInput = typeof body.userInput === "string" ? body.userInput.trim() : "";
  const presetId  = typeof body.presetId  === "string" ? body.presetId.trim()  : "";

  if (!userInput)                          return json({ error: "userInput is required" }, 400);
  if (userInput.length > MAX_PROMPT_CHARS) return json({ error: `userInput exceeds ${MAX_PROMPT_CHARS} chars` }, 400);
  if (!presetId || !(presetId in PRESETS)) return json({ error: "Unknown presetId" }, 400);

  const styleDescriptor = PRESETS[presetId];
  const finalPrompt = buildFinalPrompt(styleDescriptor, userInput);

  // ------------------- deduct credits (atomic) -------------------
  // The RPC derives the target user from auth.uid() — do not pass p_user_id.
  const { data: stickerId, error: rpcErr } = await userClient.rpc("deduct_credit_for_sticker", {
    p_cost:    STICKER_COST,
    p_preset:  presetId,
    p_prompt:  userInput,
  });

  if (rpcErr || !stickerId) {
    const msg = rpcErr?.message ?? "Credit deduction failed";
    const status = msg.includes("Insufficient") ? 402 : 400;
    return json({ error: msg }, status);
  }

  // ------------------- generate + upload -------------------
  try {
    const { bytes, contentType } = await callOpenRouter(finalPrompt);

    const ext  = contentType.includes("jpeg") ? "jpg" : "png";
    const path = `${userId}/${stickerId}.${ext}`;

    const { error: uploadErr } = await service.storage
      .from(STORAGE_BUCKET)
      .upload(path, bytes, { contentType, upsert: true });
    if (uploadErr) throw new Error(`Storage upload failed: ${uploadErr.message}`);

    const { error: updateErr } = await service
      .from("sticker_generations")
      .update({
        image_url:    path,
        final_prompt: finalPrompt,
        status:       "success",
      })
      .eq("id", stickerId);
    if (updateErr) throw new Error(`Row update failed: ${updateErr.message}`);

    const { data: signed, error: signErr } = await service.storage
      .from(STORAGE_BUCKET)
      .createSignedUrl(path, SIGNED_URL_TTL_SEC);
    if (signErr || !signed) throw new Error(`Signed URL failed: ${signErr?.message ?? "unknown"}`);

    return json({
      stickerId,
      signedUrl: signed.signedUrl,
      path,
      finalPrompt,
    });
  } catch (e) {
    console.error("generate-sticker failed", e);
    await refund(service, stickerId as string);
    return json({ error: (e as Error).message ?? "Generation failed" }, 500);
  }
});
