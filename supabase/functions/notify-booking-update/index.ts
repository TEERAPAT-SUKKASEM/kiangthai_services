import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

interface BookingRecord {
  id: string;
  customer_id: string;
  status: string;
}

interface WebhookPayload {
  type: 'UPDATE';
  table: string;
  record: BookingRecord;
  old_record: BookingRecord;
}

function getNotificationContent(
  status: string,
): { title: string; body: string } | null {
  switch (status) {
    case 'accepted':
      return {
        title: 'Booking Accepted',
        body: 'A technician has accepted your booking.',
      };
    case 'on_the_way':
      return {
        title: 'Technician On the Way',
        body: 'Your technician is on the way to your location.',
      };
    case 'in_progress':
      return {
        title: 'Work Has Started',
        body: 'Your technician has arrived and work is in progress.',
      };
    case 'completed':
      return {
        title: 'Job Completed',
        body: 'Your service is complete. Tap to leave a review!',
      };
    case 'rejected':
      return {
        title: 'Booking Not Available',
        body: 'Your booking could not be fulfilled. Please rebook.',
      };
    default:
      return null;
  }
}

async function getAccessToken(serviceAccountJson: string): Promise<string> {
  const sa = JSON.parse(serviceAccountJson);
  const now = Math.floor(Date.now() / 1000);

  const header = { alg: 'RS256', typ: 'JWT' };
  const payload = {
    iss: sa.client_email,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    iat: now,
    exp: now + 3600,
  };

  const encode = (obj: object) =>
    btoa(JSON.stringify(obj))
      .replace(/\+/g, '-')
      .replace(/\//g, '_')
      .replace(/=+$/, '');

  const signingInput = `${encode(header)}.${encode(payload)}`;

  const pemBody = (sa.private_key as string)
    .replace(/-----BEGIN.*?-----/g, '')
    .replace(/-----END.*?-----/g, '')
    .replace(/\s/g, '');

  const binaryDer = Uint8Array.from(atob(pemBody), (c) => c.charCodeAt(0));

  const cryptoKey = await crypto.subtle.importKey(
    'pkcs8',
    binaryDer,
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign'],
  );

  const signatureBytes = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    cryptoKey,
    new TextEncoder().encode(signingInput),
  );

  const signatureB64 = btoa(
    String.fromCharCode(...new Uint8Array(signatureBytes)),
  )
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=+$/, '');

  const jwt = `${signingInput}.${signatureB64}`;

  const tokenRes = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: jwt,
    }),
  });

  const tokenData = await tokenRes.json();
  return tokenData.access_token as string;
}

async function sendFcmNotification(
  fcmToken: string,
  title: string,
  body: string,
  projectId: string,
  accessToken: string,
): Promise<void> {
  const res = await fetch(
    `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
    {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${accessToken}`,
      },
      body: JSON.stringify({
        message: {
          token: fcmToken,
          notification: { title, body },
          android: {
            notification: {
              channel_id: 'booking_status_channel',
              priority: 'HIGH',
            },
          },
          apns: {
            payload: { aps: { alert: { title, body }, sound: 'default' } },
          },
        },
      }),
    },
  );

  if (!res.ok) {
    const err = await res.text();
    console.error('FCM send failed:', res.status, err);
    throw new Error(`FCM error: ${res.status}`);
  }
}

serve(async (req: Request) => {
  try {
    const payload = (await req.json()) as WebhookPayload;

    if (payload.type !== 'UPDATE' || payload.table !== 'bookings') {
      return new Response('ignored', { status: 200 });
    }

    const { status: newStatus } = payload.record;
    const { status: oldStatus } = payload.old_record;

    if (newStatus === oldStatus) {
      return new Response('no change', { status: 200 });
    }

    const content = getNotificationContent(newStatus);
    if (!content) {
      return new Response('no notification for this status', { status: 200 });
    }

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    );

    const { data: profile, error } = await supabase
      .from('profiles')
      .select('fcm_token')
      .eq('id', payload.record.customer_id)
      .single();

    if (error || !profile?.fcm_token) {
      console.log('No FCM token for customer:', payload.record.customer_id);
      return new Response('no fcm_token', { status: 200 });
    }

    const serviceAccountJson = Deno.env.get('FIREBASE_SERVICE_ACCOUNT_JSON')!;
    const projectId = JSON.parse(serviceAccountJson).project_id as string;
    const accessToken = await getAccessToken(serviceAccountJson);

    await sendFcmNotification(
      profile.fcm_token,
      content.title,
      content.body,
      projectId,
      accessToken,
    );

    return new Response('notification sent', { status: 200 });
  } catch (err) {
    console.error('Edge function error:', err);
    return new Response(String(err), { status: 500 });
  }
});
