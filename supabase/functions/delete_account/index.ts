// deno-lint-ignore-file no-explicit-any
// Supabase Edge Function: delete_account
// - Revokes Apple Sign-In token if user signed in with Apple (required by Apple)
// - Deletes the user via admin API (cascades to all related data)
// - Called from the client when user requests account deletion

import { createClient } from "npm:@supabase/supabase-js@2";
import { SignJWT, importPKCS8 } from "npm:jose@5";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

function jsonResponse(status: number, body: any) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json", ...corsHeaders },
  });
}

/**
 * Generate Apple client_secret JWT for token revocation.
 * See: https://developer.apple.com/documentation/sign_in_with_apple/generate_and_validate_tokens
 */
async function generateAppleClientSecret(): Promise<string | null> {
  const teamId = Deno.env.get("APPLE_TEAM_ID");
  const keyId = Deno.env.get("APPLE_KEY_ID");
  const clientId = Deno.env.get("APPLE_CLIENT_ID"); // Services ID (e.g., top.helptothe.babysteps)
  const privateKeyPem = Deno.env.get("APPLE_PRIVATE_KEY");

  if (!teamId || !keyId || !clientId || !privateKeyPem) {
    console.log("Apple credentials not configured — skipping token revocation");
    return null;
  }

  const privateKey = await importPKCS8(privateKeyPem, "ES256");

  const now = Math.floor(Date.now() / 1000);
  const jwt = await new SignJWT({})
    .setProtectedHeader({ alg: "ES256", kid: keyId })
    .setIssuer(teamId)
    .setIssuedAt(now)
    .setExpirationTime(now + 15777000) // 6 months
    .setAudience("https://appleid.apple.com")
    .setSubject(clientId)
    .sign(privateKey);

  return jwt;
}

/**
 * Revoke Apple Sign-In token.
 * See: https://developer.apple.com/documentation/sign_in_with_apple/revoke_tokens
 */
async function revokeAppleToken(
  refreshToken: string,
  clientSecret: string,
): Promise<boolean> {
  const clientId = Deno.env.get("APPLE_CLIENT_ID");
  if (!clientId) return false;

  try {
    const response = await fetch("https://appleid.apple.com/auth/revoke", {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body: new URLSearchParams({
        client_id: clientId,
        client_secret: clientSecret,
        token: refreshToken,
        token_type_hint: "refresh_token",
      }),
    });

    if (response.ok) {
      console.log("Apple token revoked successfully");
      return true;
    } else {
      const text = await response.text();
      console.error(
        `Apple token revocation failed: ${response.status} ${text}`,
      );
      return false;
    }
  } catch (e) {
    console.error(`Apple token revocation error: ${e}`);
    return false;
  }
}

Deno.serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    // Verify the user is authenticated
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return jsonResponse(401, { error: "Missing authorization header" });
    }

    // Create admin client with service role key
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, serviceRoleKey);

    // Create user-scoped client to verify the JWT
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
    const userClient = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authHeader } },
    });

    const {
      data: { user },
      error: userError,
    } = await userClient.auth.getUser();
    if (userError || !user) {
      return jsonResponse(401, { error: "Invalid or expired token" });
    }

    const userId = user.id;
    console.log(`Processing account deletion for user: ${userId}`);

    // Check if user signed in with Apple and attempt token revocation
    const { data: identities } = await supabase
      .from("auth.identities")
      .select("*")
      .eq("user_id", userId)
      .eq("provider", "apple");

    // Try to get Apple identity from admin API instead
    const { data: adminUser } = await supabase.auth.admin.getUserById(userId);
    const appleIdentity = adminUser?.user?.identities?.find(
      (i: any) => i.provider === "apple",
    );

    if (appleIdentity) {
      console.log("User has Apple identity — attempting token revocation");
      const clientSecret = await generateAppleClientSecret();
      if (clientSecret) {
        // The refresh token may be stored in the identity's credential data
        // Supabase stores provider tokens in the session, not always in identities
        // If we have a refresh token, revoke it
        const providerRefreshToken =
          appleIdentity.identity_data?.refresh_token ||
          appleIdentity.identity_data?.provider_refresh_token;

        if (providerRefreshToken) {
          await revokeAppleToken(providerRefreshToken, clientSecret);
        } else {
          console.log(
            "No Apple refresh token found in identity data — " +
              "token may have already expired or was not stored",
          );
        }
      }
    }

    // Delete baby photos from storage
    try {
      const { data: babies } = await supabase
        .from("babies")
        .select("id")
        .eq("user_id", userId);

      if (babies && babies.length > 0) {
        for (const baby of babies) {
          const { data: files } = await supabase.storage
            .from("baby-photos")
            .list(`${userId}/${baby.id}`);

          if (files && files.length > 0) {
            const filePaths = files.map(
              (f: any) => `${userId}/${baby.id}/${f.name}`,
            );
            await supabase.storage.from("baby-photos").remove(filePaths);
          }
        }
      }
    } catch (e) {
      console.error(`Storage cleanup error (non-fatal): ${e}`);
    }

    // Delete the user via admin API — this cascades to all related tables
    const { error: deleteError } = await supabase.auth.admin.deleteUser(userId);

    if (deleteError) {
      console.error(`Failed to delete user: ${deleteError.message}`);
      return jsonResponse(500, { error: "Failed to delete account" });
    }

    console.log(`User ${userId} deleted successfully`);
    return jsonResponse(200, { success: true, message: "Account deleted" });
  } catch (e) {
    console.error(`Account deletion error: ${e}`);
    return jsonResponse(500, { error: "Internal server error" });
  }
});
