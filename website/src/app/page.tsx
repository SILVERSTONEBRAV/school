import Link from "next/link";
import { siteConfig } from "@/lib/config";
import { getSchool } from "@/lib/data";

export default async function HomePage() {
  const school = await getSchool();

  return (
    <>
      <section className="bg-gradient-to-br from-brand-900 via-brand-700 to-brand-600 text-white">
        <div className="container-page py-20 sm:py-28">
          <p className="text-sm font-semibold uppercase tracking-wider text-brand-100">
            Welcome
          </p>
          <h1 className="mt-3 max-w-3xl text-4xl font-bold tracking-tight sm:text-5xl">
            {school?.name ?? "Our School"}
          </h1>
          <p className="mt-5 max-w-2xl text-lg text-brand-100">
            {school?.tagline ??
              school?.motto ??
              "Excellence in education. Access resources, downloads, and our community portal."}
          </p>
          <div className="mt-8 flex flex-wrap gap-3">
            <Link
              href="/get-app"
              className="rounded-xl bg-white px-5 py-2.5 text-sm font-semibold text-brand-700 hover:bg-brand-50"
            >
              Get the app
            </Link>
            <a
              href={`${siteConfig.appUrl}/login`}
              className="rounded-xl border border-white/40 px-5 py-2.5 text-sm font-semibold text-white hover:bg-white/10"
            >
              Continue on web
            </a>
            <Link
              href="/about"
              className="rounded-xl border border-white/40 px-5 py-2.5 text-sm font-semibold text-white hover:bg-white/10"
            >
              Learn more
            </Link>
          </div>
        </div>
      </section>

      <section className="container-page py-16">
        <h2 className="section-title">Everything in one place</h2>
        <p className="section-lead">
          Browse public information here. Students, parents, and staff sign in to
          the app for grades, fees, assignments, and more.
        </p>
        <div className="mt-10 grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
          {[
            {
              title: "Downloads",
              desc: "Forms, prospectus, policies",
              href: "/downloads",
            },
            {
              title: "Gallery",
              desc: "Campus life and events",
              href: "/gallery",
            },
            {
              title: "FAQs & Help",
              desc: "Answers and support articles",
              href: "/faqs",
            },
            {
              title: "Contact",
              desc: "Departments and phone numbers",
              href: "/contact",
            },
            {
              title: "Success stories",
              desc: "Alumni and student achievements",
              href: "/stories",
            },
            {
              title: "Location",
              desc: "Find us on the map",
              href: "/location",
            },
          ].map((item) => (
            <Link key={item.href} href={item.href} className="card hover:border-brand-200">
              <h3 className="font-semibold text-slate-900">{item.title}</h3>
              <p className="mt-2 text-sm text-slate-600">{item.desc}</p>
            </Link>
          ))}
        </div>
      </section>

      {(school?.mission || school?.vision) && (
        <section className="bg-white py-16">
          <div className="container-page grid gap-8 md:grid-cols-2">
            {school.mission && (
              <div className="card">
                <h2 className="text-xl font-bold text-brand-700">Mission</h2>
                <p className="mt-3 whitespace-pre-wrap text-slate-700">
                  {school.mission}
                </p>
              </div>
            )}
            {school.vision && (
              <div className="card">
                <h2 className="text-xl font-bold text-brand-700">Vision</h2>
                <p className="mt-3 whitespace-pre-wrap text-slate-700">
                  {school.vision}
                </p>
              </div>
            )}
          </div>
        </section>
      )}
    </>
  );
}
