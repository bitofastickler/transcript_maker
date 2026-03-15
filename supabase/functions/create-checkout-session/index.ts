import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import Stripe from "npm:stripe@15.12.0";

const DEFAULT_TRIAL_DAYS = 30;

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { price_id, success_url, cancel_url } = await req.json();
    if (!price_id || !success_url || !cancel_url) {
      return jsonResponse(
        { error: "price_id, success_url, and cancel_url are required." },
        400,
      );
    }

    const authHeader = req.headers.get("Authorization");
    const token = authHeader?.replace("Bearer ", "");
    if (!token) {
      return jsonResponse({ error: "Missing Authorization header." }, 401);
    }

    const supabase = createSupabaseClient();
    const { data: userData, error: userError } = await supabase.auth.getUser(
      token,
    );
    if (userError || !userData.user) {
      return jsonResponse({ error: "Unauthorized." }, 401);
    }

    const user = userData.user;
    const profile = await fetchProfile(supabase, user.id);
    const stripe = createStripeClient();
    const trialDays = resolveTrialDays();

    let stripeCustomerId = profile.stripe_customer_id ?? null;
    if (!stripeCustomerId) {
      const customer = await stripe.customers.create({
        email: user.email ?? undefined,
        metadata: { supabase_user_id: user.id },
      });
      stripeCustomerId = customer.id;
      const { error: updateError } = await supabase
        .from("profiles")
        .update({ stripe_customer_id: stripeCustomerId })
        .eq("id", user.id);
      if (updateError) {
        throw new Error(
          `Unable to persist Stripe customer: ${updateError.message}`,
        );
      }
    }

    const hasSubscriptionHistory = await customerHasSubscriptionHistory(
      stripe,
      stripeCustomerId,
    );

    const session = await stripe.checkout.sessions.create({
      mode: "subscription",
      customer: stripeCustomerId,
      line_items: [{ price: price_id, quantity: 1 }],
      ...(trialDays > 0 && !hasSubscriptionHistory
        ? {
            subscription_data: {
              trial_period_days: trialDays,
            },
          }
        : {}),
      success_url: `${success_url}?session_id={CHECKOUT_SESSION_ID}`,
      cancel_url,
    });

    return jsonResponse({ url: session.url }, 200);
  } catch (error) {
    return jsonResponse({ error: String(error) }, 500);
  }
});

function createSupabaseClient() {
  const url = Deno.env.get("SUPABASE_URL");
  const key = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!url || !key) {
    throw new Error("Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY.");
  }
  return createClient(url, key);
}

function createStripeClient() {
  const secret = Deno.env.get("STRIPE_SECRET_KEY");
  if (!secret) {
    throw new Error("Missing STRIPE_SECRET_KEY.");
  }
  return new Stripe(secret, { apiVersion: "2024-06-20" });
}

function resolveTrialDays() {
  const configured = Deno.env.get("STRIPE_TRIAL_DAYS");
  if (!configured) {
    return DEFAULT_TRIAL_DAYS;
  }
  const parsed = Number.parseInt(configured, 10);
  if (!Number.isFinite(parsed) || parsed < 0) {
    return DEFAULT_TRIAL_DAYS;
  }
  return parsed;
}

async function customerHasSubscriptionHistory(
  stripe: ReturnType<typeof createStripeClient>,
  customerId: string,
) {
  const { data } = await stripe.subscriptions.list({
    customer: customerId,
    status: "all",
    limit: 1,
  });
  return data.length > 0;
}

async function fetchProfile(
  supabase: ReturnType<typeof createSupabaseClient>,
  userId: string,
) {
  const { data, error } = await supabase
    .from("profiles")
    .select("stripe_customer_id")
    .eq("id", userId)
    .single();
  if (error || !data) {
    throw new Error("Unable to load user profile.");
  }
  return data;
}

function jsonResponse(body: Record<string, unknown>, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
