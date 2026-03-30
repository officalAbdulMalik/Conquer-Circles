import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";


serve(async (req) => {

  try {
    // Standard Supabase Edge Function environment variables:
    // They are automatically provided by the Supabase platform.
    const supabaseClient = createClient(
      "https://dpvelnjzovjhxgpjvtay.supabase.co",
      "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRwdmVsbmp6b3ZqaHhncGp2dGF5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzEzOTI0MTAsImV4cCI6MjA4Njk2ODQxMH0.Nbssvqd6jnpXXQpdDCzfrPpx1k4CxBiP9FDQSVNkous",
    );

    const { user_id, circle_id, message } = await req.json();

    if (!user_id || !circle_id || !message) {
      throw new Error("Missing user_id, circle_id or message");
    }

    // Use Service Role key to bypass RLS and act on behalf of the specified user_id
    const { data: profile } = await supabaseClient
      .from("profiles")
      .select("username, avatar_url")
      .eq("id", user_id)
      .single();

    const { data: insertedMessage, error: insertError } = await supabaseClient
      .from("circle_messages")
      .insert({
        circle_id,
        user_id: user_id,
        message,
        sender_info: {
          username: profile?.username || "User",
          avatar_url: profile?.avatar_url || null,
        },
      })
      .select()
      .single();

    if (insertError) throw insertError;

    return new Response(JSON.stringify(insertedMessage), {
      headers: { "Content-Type": "application/json" },
      status: 200,
    });
  } catch (error) {
    return new Response(JSON.stringify({
      error:
        "Error: " + error.message
    }), {
      headers: { "Content-Type": "application/json" },
      status: 400,
    });
  }
});
