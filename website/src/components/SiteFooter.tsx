import Link from "next/link";
import { siteConfig } from "@/lib/config";

export function SiteFooter({ schoolName }: { schoolName: string }) {
  return (
    <footer className="mt-20 border-t border-slate-200 bg-white">
      <div className="container-page grid gap-8 py-12 sm:grid-cols-2 lg:grid-cols-4">
        <div>
          <p className="font-bold text-brand-700">{schoolName}</p>
          <p className="mt-2 text-sm text-slate-600">
            Public information portal. Sign in to the app for grades, fees, and
            assignments.
          </p>
        </div>
        <div>
          <p className="font-semibold text-slate-900">Explore</p>
          <ul className="mt-3 space-y-2 text-sm text-slate-600">
            <li>
              <Link href="/about">About</Link>
            </li>
            <li>
              <Link href="/stories">Success stories</Link>
            </li>
            <li>
              <Link href="/reviews">Reviews</Link>
            </li>
            <li>
              <Link href="/location">Location</Link>
            </li>
          </ul>
        </div>
        <div>
          <p className="font-semibold text-slate-900">Resources</p>
          <ul className="mt-3 space-y-2 text-sm text-slate-600">
            <li>
              <Link href="/downloads">Downloads</Link>
            </li>
            <li>
              <Link href="/help">Help center</Link>
            </li>
            <li>
              <Link href="/faqs">FAQs</Link>
            </li>
            <li>
              <Link href="/gallery">Gallery</Link>
            </li>
          </ul>
        </div>
        <div>
          <p className="font-semibold text-slate-900">App</p>
          <ul className="mt-3 space-y-2 text-sm text-slate-600">
            <li>
              <Link href="/get-app">Get the app</Link>
            </li>
            <li>
              <a href={`${siteConfig.appUrl}/login`}>Continue on web</a>
            </li>
            <li>
              <a href={`${siteConfig.appUrl}/register`}>Create account</a>
            </li>
          </ul>
        </div>
      </div>
      <div className="border-t border-slate-100 py-6 text-center text-sm text-slate-500">
        © {new Date().getFullYear()} {schoolName}. All rights reserved.
      </div>
    </footer>
  );
}
