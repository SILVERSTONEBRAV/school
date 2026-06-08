import { getSchool } from "@/lib/data";

export default async function LocationPage() {
  const school = await getSchool();

  return (
    <div className="container-page py-16">
      <h1 className="section-title">Location</h1>
      <p className="section-lead">Visit us or get directions.</p>

      <div className="mt-10 card max-w-2xl">
        {school?.address && (
          <p className="text-slate-700">{school.address}</p>
        )}
        {school?.phone && (
          <p className="mt-3 text-sm">
            Phone:{" "}
            <a href={`tel:${school.phone}`} className="text-brand-600">
              {school.phone}
            </a>
          </p>
        )}
        {school?.map_url && (
          <a
            href={school.map_url}
            target="_blank"
            rel="noopener noreferrer"
            className="btn-primary mt-6 inline-flex"
          >
            Open in Google Maps
          </a>
        )}
        {!school?.address && !school?.map_url && (
          <p className="text-slate-600">Location details coming soon.</p>
        )}
      </div>
    </div>
  );
}
