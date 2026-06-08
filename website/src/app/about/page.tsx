import { getSchool } from "@/lib/data";

export default async function AboutPage() {
  const school = await getSchool();

  return (
    <div className="container-page py-16">
      <h1 className="section-title">About us</h1>
      <p className="section-lead">
        {school?.tagline ?? "Learn more about our school community."}
      </p>

      <div className="mt-10 space-y-8">
        {school?.about && (
          <div className="card">
            <h2 className="text-xl font-semibold">Who we are</h2>
            <p className="mt-3 whitespace-pre-wrap text-slate-700">
              {school.about}
            </p>
          </div>
        )}
        <div className="grid gap-6 md:grid-cols-2">
          {school?.mission && (
            <div className="card">
              <h2 className="text-xl font-semibold text-brand-700">Mission</h2>
              <p className="mt-3 whitespace-pre-wrap text-slate-700">
                {school.mission}
              </p>
            </div>
          )}
          {school?.vision && (
            <div className="card">
              <h2 className="text-xl font-semibold text-brand-700">Vision</h2>
              <p className="mt-3 whitespace-pre-wrap text-slate-700">
                {school.vision}
              </p>
            </div>
          )}
        </div>
        {school?.established_year && (
          <p className="text-sm text-slate-500">
            Established {school.established_year}
          </p>
        )}
      </div>
    </div>
  );
}
