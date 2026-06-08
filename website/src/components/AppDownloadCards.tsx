import {
  appReleaseButtonLabel,
  platformMeta,
  resolveAppReleaseUrl,
} from "@/lib/app-releases";
import { siteConfig } from "@/lib/config";
import type { AppRelease } from "@/lib/types";

type Props = {
  releases: AppRelease[];
  emptyMessage?: string;
};

export function AppDownloadCards({ releases, emptyMessage }: Props) {
  if (releases.length === 0) {
    return (
      <div className="card sm:col-span-2">
        <p className="text-slate-700">
          {emptyMessage ??
            "App download links are being configured by the school admin."}
        </p>
        <a
          href={`${siteConfig.appUrl.replace(/\/$/, "")}/login`}
          className="btn-primary mt-4 inline-flex"
        >
          Continue on web
        </a>
      </div>
    );
  }

  return (
    <>
      {releases.map((release) => {
        const meta = platformMeta[release.platform] ?? {
          label: release.platform,
          icon: "📦",
        };
        const url = resolveAppReleaseUrl(
          release.platform,
          release.download_url,
        );

        return (
          <div key={release.id} className="card">
            <div className="flex items-start gap-4">
              <span className="text-3xl" aria-hidden>
                {meta.icon}
              </span>
              <div className="flex-1">
                <h2 className="text-lg font-semibold">{meta.label}</h2>
                {release.version && (
                  <p className="text-sm text-slate-500">v{release.version}</p>
                )}
                {release.release_notes && (
                  <p className="mt-2 text-sm text-slate-600">
                    {release.release_notes}
                  </p>
                )}
                <div className="mt-4">
                  {url ? (
                    <a
                      href={url}
                      className="btn-primary"
                      target={release.platform === "web" ? "_self" : "_blank"}
                      rel="noopener noreferrer"
                    >
                      {appReleaseButtonLabel(release.platform)}
                    </a>
                  ) : (
                    <span className="text-sm text-slate-500">
                      Link coming soon — configure in Admin → Portal CMS
                    </span>
                  )}
                </div>
              </div>
            </div>
          </div>
        );
      })}
    </>
  );
}
