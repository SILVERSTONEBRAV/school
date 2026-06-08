import Link from "next/link";
import { siteConfig } from "@/lib/config";

const nav = [
  { href: "/about", label: "About" },
  { href: "/downloads", label: "Downloads" },
  { href: "/gallery", label: "Gallery" },
  { href: "/faqs", label: "FAQs" },
  { href: "/contact", label: "Contact" },
  { href: "/get-app", label: "Get the App" },
];

export function SiteHeader({ schoolName }: { schoolName: string }) {
  return (
    <header className="sticky top-0 z-50 border-b border-slate-200/80 bg-white/90 backdrop-blur">
      <div className="container-page flex h-16 items-center justify-between gap-4">
        <Link href="/" className="text-lg font-bold text-brand-700">
          {schoolName}
        </Link>
        <nav className="hidden items-center gap-6 md:flex">
          {nav.map((item) => (
            <Link
              key={item.href}
              href={item.href}
              className="text-sm font-medium text-slate-600 hover:text-brand-600"
            >
              {item.label}
            </Link>
          ))}
        </nav>
        <div className="flex items-center gap-2">
          <Link href="/get-app" className="btn-secondary hidden sm:inline-flex">
            Download
          </Link>
          <a href={`${siteConfig.appUrl}/login`} className="btn-primary">
            Sign in
          </a>
        </div>
      </div>
    </header>
  );
}
