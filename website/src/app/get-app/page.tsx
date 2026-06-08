import { siteConfig } from "@/lib/config";
import { getAppReleases } from "@/lib/data";

const platformMeta: Record<
  string,
  { label: string; icon: string; fallbackUrl?: string }
> = {
  web: { label: "Web app", icon: "🌐" },
  windows: { label: "Windows", icon: "🖥️" },
  android: { label: "Android", icon: "🤖" },
  ios: { label: "iPhone / iPad", icon: "📱" },
};

export default async function GetAppPage() {
  const releases = await getAppReleases();

  function resolveUrl(platform: string, downloadUrl: string | null) {
    if (platform === "web") {
      return downloadUrl ?? `${siteConfig.appUrl}/login`;
    }
    return downloadUrl;
  }

  return (
    <div className="container-page py-16">
      <h1 className="section-title">Get the app</h1>
      <p className="section-lead">
        Download for your device or continue in the browser — same account,
        same school data.
      </p>

      <div className="mt-10 grid gap-6 sm:grid-cols-2">
        {releases.length === 0 ? (
          <div className="card sm:col-span-2">
            <p className="text-slate-700">
              App download links are being configured by the school admin.
            </p>
            <a href={`${siteConfig.appUrl}/login`} className="btn-primary mt-4 inline-flex">
              Continue on web
            </a>
          </div>
        ) : (
          releases.map((release) => {
            const meta = platformMeta[release.platform] ?? {
              label: release.platform,
              icon: "📦",
            };
            const url = resolveUrl(release.platform, release.download_url);

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
                          {release.platform === "web"
                            ? "Continue on web"
                            : "Download"}
                        </a>
                      ) : (
                        <span className="text-sm text-slate-500">
                          Link coming soon — ask admin to configure in Portal CMS
                        </span>
                      )}
                    </div>
                  </div>
                </div>
              </div>
            );
          })
        )}
      </div>

      <div className="mt-12 card max-w-2xl bg-slate-50">
        <h2 className="font-semibold text-slate-900">New here?</h2>
        <p className="mt-2 text-sm text-slate-600">
          Students and parents can register from the app. Staff accounts are
          created by school administrators.
        </p>
        <div className="mt-4 flex flex-wrap gap-3">
          <a href={`${siteConfig.appUrl}/register`} className="btn-primary">
            Create account
          </a>
          <a href={`${siteConfig.appUrl}/login`} className="btn-secondary">
            Sign in
          </a>
        </div>
      </div>
    </div>
  );
}
