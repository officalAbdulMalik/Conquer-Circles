import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

serve(async (req) => {
  try {
    const authHeader = req.headers.get("authorization");
    if (!authHeader) {
      throw new Error("Missing authorization header");
    }

    const { message_id, emoji } = await req.json();
    if (!message_id || !emoji) {
      throw new Error("Missing message_id or emoji");
    }

    const supabaseClient = createClient(
      "https://dpvelnjzovjhxgpjvtay.supabase.co",
      "eyJhbGciOiJIUzI1NiIsInJlZiI6ImRwdmVsbmp6dGF5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzEzOTI0MTAsImV4cCI6MjA4Njk2ODQxMH0.Nbssvqd6jnpXXQpdDCzfrPpx1k4CxBiP9FDQSVNkous",
      {
        global: {
          headers: {
            Authorization: authHeader,
          },
        },
      },
    );

    const { data: userData, error: authError } = await supabaseClient.auth.getUser();
    if (authError || !userData?.user?.id) {
      throw new Error(authError?.message || "Failed to authenticate user");
    }

    const userId = userData.user.id;

    const { data: existingReaction, error: existingError } = await supabaseClient
      .from("circle_message_reactions")
      .select("id")
      .eq("message_id", message_id)
      .eq("user_id", userId)
      .eq("emoji", emoji)
      .maybeSingle();

    if (existingError) {
      throw existingError;
    }

    if (existingReaction) {
      const { error: deleteError } = await supabaseClient
        .from("circle_message_reactions")
        .delete()
        .eq("message_id", message_id)
        .eq("user_id", userId)
        .eq("emoji", emoji);

      if (deleteError) throw deleteError;
    } else {
      const { error: insertError } = await supabaseClient
        .from("circle_message_reactions")
        .insert({ message_id, user_id: userId, emoji });

      if (insertError) throw insertError;
    }

    const { data: updatedReactions, error: countError } = await supabaseClient
      .from("circle_message_reactions")
      .select("emoji, user_id")
      .eq("message_id", message_id);

    if (countError) throw countError;

    const aggregated = (updatedReactions ?? []).reduce((acc, row) => {
      const emojiKey = row.emoji;
      if (!emojiKey) return acc;
      const existing = acc[emojiKey] ?? { emoji: emojiKey, count: 0, selected: false };
      existing.count += 1;
      if (row.user_id === userId) existing.selected = true;
      acc[emojiKey] = existing;
      return acc;
    }, {} as Record<string, { emoji: string; count: number; selected: boolean }>);

    return new Response(JSON.stringify(Object.values(aggregated)), {
      headers: { "Content-Type": "application/json" },
      status: 200,
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { "Content-Type": "application/json" },
      status: 400,
    });
  }
});
