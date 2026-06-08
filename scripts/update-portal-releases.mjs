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
  Prefer: "return=representation",
};

async function rest(path, options = {}) {
  const res = await fetch(`${supabaseUrl}/rest/v1/${path}`, {
    ...options,
    headers: { ...headers, ...options.headers },
  });
  const text = await res.text();
  if (!res.ok) {
    throw new Error(`${path} ${res.status}: ${text}`);
  }
  if (!text) return null;
  try {
    return JSON.parse(text);
  } catch {
    return text;
  }
}

async function getSchoolId() {
  if (schoolIdEnv) return schoolIdEnv;
  const rows = await rest("schools?select=id&order=created_at.asc&limit=1");
  if (!rows?.[0]?.id) throw new Error("No school row found");
  return rows[0].id;
}

async function upsertRelease(schoolId, platform, downloadUrl, notes, sortOrder) {
  const row = {
    school_id: schoolId,
    platform,
    download_url: downloadUrl,
    version,
    release_notes: notes,
    is_enabled: true,
    sort_order: sortOrder,
    updated_at: new Date().toISOString(),
  };

  const result = await rest(
    "portal_app_releases?on_conflict=school_id,platform",
    {
      method: "POST",
      headers: { Prefer: "resolution=merge-duplicates,return=representation" },
      body: JSON.stringify([row]),
    },
  );

  if (!result?.length) {
    throw new Error(`No row upserted for platform ${platform}`);
  }

  console.log(`Updated ${platform} → v${version} → ${downloadUrl}`);
}

async function main() {
  const schoolId = await getSchoolId();
  console.log(`School id: ${schoolId}`);

  const webLogin =
    webUrl != null ? webUrl.replace(/\/$/, "") + "/login" : null;

  if (webLogin) {
    await upsertRelease(
      schoolId,
      "web",
      webLogin,
      "Continue in browser — no install needed",
      1,
    );
  }

  if (windowsUrl) {
    await upsertRelease(
      schoolId,
      "windows",
      windowsUrl,
      `Windows desktop build v${version}`,
      2,
    );
  }

  if (androidUrl) {
    await upsertRelease(
      schoolId,
      "android",
      androidUrl,
      `Android APK v${version}`,
      3,
    );
  }

  console.log("portal_app_releases updated.");
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
