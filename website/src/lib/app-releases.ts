import { siteConfig } from "./config";
import type { AppRelease } from "./types";

export const platformMeta: Record<
  string,
  { label: string; icon: string }
> = {
  web: { label: "Web app", icon: "🌐" },
  windows: { label: "Windows", icon: "🖥️" },
  android: { label: "Android", icon: "🤖" },
  ios: { label: "iPhone / iPad", icon: "📱" },
};

/** Resolve the href for a release row (DB first, sensible fallbacks). */
export function resolveAppReleaseUrl(
  platform: string,
  downloadUrl: string | null,
): string | null {
  if (platform === "web") {
    return (
      downloadUrl ??
      (siteConfig.appUrl ? `${siteConfig.appUrl.replace(/\/$/, "")}/login` : null)
    );
  }
  return downloadUrl;
}

export function appReleaseButtonLabel(platform: string): string {
  if (platform === "web") return "Continue on web";
  return "Download";
}

export function webLoginUrl(releases: AppRelease[]): string {
  const web = releases.find((r) => r.platform === "web");
  return (
    resolveAppReleaseUrl("web", web?.download_url ?? null) ??
    `${siteConfig.appUrl.replace(/\/$/, "")}/login`
  );
}
