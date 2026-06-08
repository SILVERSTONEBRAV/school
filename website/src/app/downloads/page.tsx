import { getDownloads } from "@/lib/data";

export default async function DownloadsPage() {
  const downloads = await getDownloads();

  return (
    <div className="container-page py-16">
      <h1 className="section-title">Downloads</h1>
      <p className="section-lead">
        Prospectus, forms, policies, and other school documents.
      </p>

      {downloads.length === 0 ? (
        <p className="mt-10 text-slate-600">No documents published yet.</p>
      ) : (
        <div className="mt-10 grid gap-4">
          {downloads.map((item) => (
            <div key={item.id} className="card flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
              <div>
                <p className="font-semibold text-slate-900">{item.title}</p>
                {item.description && (
                  <p className="mt-1 text-sm text-slate-600">{item.description}</p>
                )}
                {item.category && (
                  <span className="mt-2 inline-block rounded-full bg-slate-100 px-2 py-0.5 text-xs text-slate-600">
                    {item.category}
                  </span>
                )}
              </div>
              <a href={item.file_url} className="btn-primary shrink-0" download>
                Download
              </a>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
