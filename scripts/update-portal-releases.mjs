#!/usr/bin/env node
/**
 * Updates portal_app_releases in Supabase after a CI release.
 *
 * Usage:
 *   node scripts/update-portal-releases.mjs <version> <windowsUrl> <androidUrl> [webUrl]
 *
 * Env: SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, SCHOOL_ID (optional)
 */

const version = process.argv[2];
const windowsUrl = process.argv[3] || null;
const androidUrl = process.argv[4] || null;
const webUrl = process.argv[5] || process.env.APP_BASE_URL || null;

const supabaseUrl = process.env.SUPABASE_URL;
const serviceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
const schoolIdEnv = process.env.SCHOOL_ID;

if (!version || !supabaseUrl || !serviceKey) {
  console.error(
    "Usage: node update-portal-releases.mjs <version> <windowsUrl> <androidUrl> [webUrl]",
  );
  console.error("Requires SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY");
  process.exit(1);
}

const headers = {
  apikey: serviceKey,
  Authorization: `Bearer ${serviceKey}`,
  "Content-Type": "application/json",
  Prefer: "return=minimal",
};

async function rest(path, options = {}) {
  const res = await fetch(`${supabaseUrl}/rest/v1/${path}`, {
    ...options,
    headers: { ...headers, ...options.headers },
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`${path} ${res.status}: ${text}`);
  }
  if (res.status === 204) return null;
  return res.json();
}

async function getSchoolId() {
  if (schoolIdEnv) return schoolIdEnv;
  const rows = await rest("schools?select=id&order=created_at.asc&limit=1");
  if (!rows?.[0]?.id) throw new Error("No school row found");
  return rows[0].id;
}

async function patchRelease(schoolId, platform, downloadUrl, notes) {
  const loginUrl =
    platform === "web" && webUrl
      ? webUrl.replace(/\/$/, "") + "/login"
      : downloadUrl;

  await rest(
    `portal_app_releases?school_id=eq.${schoolId}&platform=eq.${platform}`,
    {
      method: "PATCH",
      body: JSON.stringify({
        download_url: loginUrl,
        version,
        release_notes: notes,
        is_enabled: true,
        updated_at: new Date().toISOString(),
      }),
    },
  );
  console.log(`Updated ${platform} → v${version}`);
}

async function main() {
  const schoolId = await getSchoolId();
  console.log(`School id: ${schoolId}`);

  if (windowsUrl) {
    await patchRelease(
      schoolId,
      "windows",
      windowsUrl,
      `Windows desktop build v${version}`,
    );
  }

  if (androidUrl) {
    await patchRelease(
      schoolId,
      "android",
      androidUrl,
      `Android APK v${version}`,
    );
  }

  if (webUrl) {
    await patchRelease(
      schoolId,
      "web",
      webUrl.replace(/\/$/, "") + "/login",
      "Continue in browser — no install needed",
    );
  }

  console.log("portal_app_releases updated.");
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
