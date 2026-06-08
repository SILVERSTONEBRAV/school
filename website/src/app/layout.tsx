import type { Metadata } from "next";
import { SiteFooter } from "@/components/SiteFooter";
import { SiteHeader } from "@/components/SiteHeader";
import { getSchool } from "@/lib/data";
import "./globals.css";

// Fetch CMS data at request time (build succeeds without Supabase env vars).
export const dynamic = "force-dynamic";

export async function generateMetadata(): Promise<Metadata> {
  const school = await getSchool();
  return {
    title: {
      default: school?.name ?? "School",
      template: `%s · ${school?.name ?? "School"}`,
    },
    description:
      school?.tagline ??
      school?.motto ??
      "Official school website — downloads, news, and app access.",
  };
}

export default async function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  const school = await getSchool();
  const schoolName = school?.name ?? "School";

  return (
    <html lang="en">
      <body className="min-h-screen font-sans antialiased">
        <SiteHeader schoolName={schoolName} />
        <main>{children}</main>
        <SiteFooter schoolName={schoolName} />
      </body>
    </html>
  );
}
