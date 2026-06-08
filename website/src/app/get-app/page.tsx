import { AppDownloadCards } from "@/components/AppDownloadCards";
import { webLoginUrl } from "@/lib/app-releases";
import { siteConfig } from "@/lib/config";
import { getAppReleases } from "@/lib/data";

export const revalidate = 60;

export default async function GetAppPage() {
  const releases = await getAppReleases();
  const loginUrl = webLoginUrl(releases);

  return (
    <div className="container-page py-16">
      <h1 className="section-title">Get the app</h1>
      <p className="section-lead">
        Download for your device or continue in the browser — same account,
        same school data.
      </p>

      <div className="mt-10 grid gap-6 sm:grid-cols-2">
        <AppDownloadCards releases={releases} />
      </div>

      <div className="mt-12 card max-w-2xl bg-slate-50">
        <h2 className="font-semibold text-slate-900">New here?</h2>
        <p className="mt-2 text-sm text-slate-600">
          Students and parents can register from the app. Staff accounts are
          created by school administrators.
        </p>
        <div className="mt-4 flex flex-wrap gap-3">
          <a href={`${siteConfig.appUrl.replace(/\/$/, "")}/register`} className="btn-primary">
            Create account
          </a>
          <a href={loginUrl} className="btn-secondary">
            Sign in
          </a>
        </div>
      </div>
    </div>
  );
}
