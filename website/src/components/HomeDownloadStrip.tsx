import Link from "next/link";
import {
  appReleaseButtonLabel,
  platformMeta,
  resolveAppReleaseUrl,
} from "@/lib/app-releases";
import type { AppRelease } from "@/lib/types";

type Props = {
  releases: AppRelease[];
};

/** Compact download row for the home page — data from portal_app_releases. */
export function HomeDownloadStrip({ releases }: Props) {
  const installable = releases.filter(
    (r) => r.platform !== "web" && resolveAppReleaseUrl(r.platform, r.download_url),
  );

  if (installable.length === 0) return null;

  return (
    <section className="border-t border-slate-200 bg-white py-12">
      <div className="container-page">
        <div className="flex flex-col gap-6 sm:flex-row sm:items-end sm:justify-between">
          <div>
            <h2 className="section-title">Download the app</h2>
            <p className="section-lead mt-2">
              Latest builds from the school — same login on every device.
            </p>
          </div>
          <Link href="/get-app" className="btn-secondary shrink-0">
            All platforms
          </Link>
        </div>
        <div className="mt-8 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {installable.map((release) => {
            const meta = platformMeta[release.platform] ?? {
              label: release.platform,
              icon: "📦",
            };
            const url = resolveAppReleaseUrl(
              release.platform,
              release.download_url,
            )!;

            return (
              <a
                key={release.id}
                href={url}
                className="card flex items-center gap-4 hover:border-brand-200"
                target="_blank"
                rel="noopener noreferrer"
              >
                <span className="text-2xl" aria-hidden>
                  {meta.icon}
                </span>
                <div>
                  <p className="font-semibold text-slate-900">{meta.label}</p>
                  {release.version && (
                    <p className="text-sm text-slate-500">v{release.version}</p>
                  )}
                  <p className="mt-1 text-sm font-medium text-brand-600">
                    {appReleaseButtonLabel(release.platform)} →
                  </p>
                </div>
              </a>
            );
          })}
        </div>
      </div>
    </section>
  );
}
