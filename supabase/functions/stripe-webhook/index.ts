import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import Stripe from "npm:stripe@15.12.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, stripe-signature",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const webhookSecret = Deno.env.get("STRIPE_WEBHOOK_SECRET");
  if (!webhookSecret) {
    return jsonResponse({ error: "Missing STRIPE_WEBHOOK_SECRET." }, 500);
  }

  const signature = req.headers.get("stripe-signature");
  if (!signature) {
    return jsonResponse({ error: "Missing Stripe signature." }, 400);
  }

  const rawBody = await req.text();
  const stripe = createStripeClient();
  let event: Stripe.Event;

  try {
    event = stripe.webhooks.constructEvent(rawBody, signature, webhookSecret);
  } catch (error) {
    return jsonResponse({ error: `Invalid signature: ${error}` }, 400);
  }

  const supabase = createSupabaseClient();

  try {
    switch (event.type) {
      case "checkout.session.completed": {
        const session = event.data.object as Stripe.Checkout.Session;
        if (session.mode !== "subscription") break;
        const subscriptionId = asString(session.subscription);
        if (!subscriptionId) break;
        const subscription = await stripe.subscriptions.retrieve(
          subscriptionId,
        );
        await updateProfileFromSubscription(supabase, subscription);
        break;
      }
      case "customer.subscription.created":
      case "customer.subscription.updated":
      case "customer.subscription.deleted": {
        const subscription = event.data.object as Stripe.Subscription;
        await updateProfileFromSubscription(supabase, subscription);
        break;
      }
      case "invoice.payment_failed": {
        const invoice = event.data.object as Stripe.Invoice;
        const customerId = asString(invoice.customer);
        if (customerId) {
          await updateProfileStatus(
            supabase,
            customerId,
            "past_due",
            null,
          );
        }
        break;
      }
      default:
        break;
    }
  } catch (error) {
    return jsonResponse({ error: String(error) }, 500);
  }

  return jsonResponse({ received: true }, 200);
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

function asString(value: unknown): string | null {
  return typeof value === "string" && value.length > 0 ? value : null;
}

async function updateProfileFromSubscription(
  supabase: ReturnType<typeof createSupabaseClient>,
  subscription: Stripe.Subscription,
) {
  const customerId = asString(subscription.customer);
  if (!customerId) return;
  const priceId = subscription.items?.data?.[0]?.price?.id ?? null;
  const periodEnd = subscription.current_period_end
    ? new Date(subscription.current_period_end * 1000).toISOString()
    : null;

  await updateProfileStatus(
    supabase,
    customerId,
    subscription.status,
    periodEnd,
    priceId,
  );
}

async function updateProfileStatus(
  supabase: ReturnType<typeof createSupabaseClient>,
  customerId: string,
  status: string,
  periodEnd: string | null,
  tier: string | null = null,
) {
  const updates: Record<string, unknown> = {
    subscription_status: status,
    current_period_end: periodEnd,
  };
  if (tier) {
    updates.subscription_tier = tier;
  }
  const { error } = await supabase
    .from("profiles")
    .update(updates)
    .eq("stripe_customer_id", customerId);
  if (error) {
    throw new Error(`Failed to update profile: ${error.message}`);
  }
}

function jsonResponse(body: Record<string, unknown>, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
