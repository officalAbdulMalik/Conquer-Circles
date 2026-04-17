import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { GoogleAuth } from "npm:google-auth-library@^9.0.0";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const { user_id, fcm_token, title, body, data, type, territory_id } = await req.json();

    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const supabaseAdmin = createClient(supabaseUrl, serviceRoleKey);

    // 1. Determine the target FCM token
    let targetToken = fcm_token;

    if (user_id) {
      const { data: profile, error } = await supabaseAdmin
        .from('profiles')
        .select('fcm_token, notifications_enabled')
        .eq('id', user_id)
        .single();

      if (error || !profile?.fcm_token) {
        throw new Error(`Profile not found or no FCM token registered for user: ${user_id}`);
      }

      if (profile.notifications_enabled === false) {
        return new Response(JSON.stringify({ message: 'User has disabled notifications' }), {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 200,
        });
      }

      targetToken = profile.fcm_token;
    }

    if (!targetToken) {
      throw new Error('Missing target: either user_id or fcm_token must be provided.');
    }

    // 2. Authenticate with Google / FCM v1
    let serviceAccount;
    const serviceAccountJSON = Deno.env.get("FIREBASE_SERVICE_ACCOUNT");
    
    if (serviceAccountJSON) {
      serviceAccount = JSON.parse(serviceAccountJSON);
    } else {
      // Fallback to individual environment variables
      serviceAccount = {
        project_id: Deno.env.get('FIREBASE_PROJECT_ID'),
        client_email: Deno.env.get('FIREBASE_CLIENT_EMAIL'),
        private_key: Deno.env.get('FIREBASE_PRIVATE_KEY')?.replace(/\\n/g, '\n'),
      };
    }

    if (!serviceAccount.project_id || !serviceAccount.client_email || !serviceAccount.private_key) {
      throw new Error('Missing Firebase credentials (FIREBASE_SERVICE_ACCOUNT or individual vars)');
    }

    const auth = new GoogleAuth({
      credentials: {
        project_id: serviceAccount.project_id,
        client_email: serviceAccount.client_email,
        private_key: serviceAccount.private_key,
      },
      scopes: "https://www.googleapis.com/auth/firebase.messaging",
    });

    const client = await auth.getClient();
    const tokenResponse = await client.getAccessToken();
    const accessToken = tokenResponse.token;

    if (!accessToken) {
      throw new Error('Failed to generate Google Access Token');
    }

    // 3. Send the message via FCM v1 API
    const message: any = {
      token: targetToken,
      notification: {
        title: title || 'New Notification',
        body: body || '',
      },
    };

    if (data) {
      message.data = data;
    }

    const response = await fetch(
      `https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send`,
      {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${accessToken}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ message }),
      }
    );

    const result = await response.json();

    if (!response.ok) {
      console.error('FCM API Error:', JSON.stringify(result, null, 2));
      console.log('Attempted Project ID:', serviceAccount.project_id);
      throw new Error(`FCM API Error: ${result.error?.message || 'Unknown error'}`);
    }

    // 4. Record notification history in database
    if (user_id) {
      const { error: dbError } = await supabaseAdmin
        .from('notifications')
        .insert({
          user_id: user_id,
          type: type || 'general',
          territory_id: territory_id || null,
          title: title || 'New Notification',
          message: body || '',
          is_read: false,
          sent_date: new Date().toISOString().split('T')[0],
        });

      if (dbError) {
        console.error('Error recording notification history:', dbError);
      }
    }

    return new Response(JSON.stringify({ success: true, result }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    });

  } catch (error: any) {
    console.error('Error sending push notification:', error);
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 400,
    });
  }
});
