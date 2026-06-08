import { getContacts, getSchool } from "@/lib/data";

export default async function ContactPage() {
  const [school, contacts] = await Promise.all([getSchool(), getContacts()]);

  return (
    <div className="container-page py-16">
      <h1 className="section-title">Contact</h1>
      <p className="section-lead">Reach the right department directly.</p>

      <div className="mt-10 grid gap-6 lg:grid-cols-3">
        <div className="card lg:col-span-1">
          <h2 className="font-semibold text-slate-900">Main office</h2>
          {school?.address && (
            <p className="mt-3 text-sm text-slate-700">{school.address}</p>
          )}
          {school?.phone && (
            <p className="mt-2 text-sm">
              <a href={`tel:${school.phone}`} className="text-brand-600">
                {school.phone}
              </a>
            </p>
          )}
          {school?.email && (
            <p className="mt-2 text-sm">
              <a href={`mailto:${school.email}`} className="text-brand-600">
                {school.email}
              </a>
            </p>
          )}
        </div>

        <div className="space-y-4 lg:col-span-2">
          {contacts.length === 0 ? (
            <p className="text-slate-600">No department contacts listed yet.</p>
          ) : (
            contacts.map((c) => (
              <div key={c.id} className="card">
                <h3 className="font-semibold">{c.department}</h3>
                {c.contact_name && (
                  <p className="mt-1 text-sm text-slate-600">{c.contact_name}</p>
                )}
                <div className="mt-2 flex flex-wrap gap-4 text-sm">
                  {c.phone && (
                    <a href={`tel:${c.phone}`} className="text-brand-600">
                      {c.phone}
                    </a>
                  )}
                  {c.email && (
                    <a href={`mailto:${c.email}`} className="text-brand-600">
                      {c.email}
                    </a>
                  )}
                </div>
              </div>
            ))
          )}
        </div>
      </div>
    </div>
  );
}
