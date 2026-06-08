import { getHelpArticles } from "@/lib/data";

export default async function HelpPage() {
  const articles = await getHelpArticles();

  return (
    <div className="container-page py-16">
      <h1 className="section-title">Help center</h1>
      <p className="section-lead">
        Guides for parents, students, and visitors using our systems.
      </p>

      {articles.length === 0 ? (
        <p className="mt-10 text-slate-600">No help articles yet.</p>
      ) : (
        <div className="mt-10 space-y-4">
          {articles.map((article) => (
            <article key={article.id} className="card">
              <p className="text-xs font-semibold uppercase text-brand-600">
                {article.category ?? "Help"}
              </p>
              <h2 className="mt-1 text-xl font-semibold">{article.title}</h2>
              <p className="mt-3 whitespace-pre-wrap text-slate-700">
                {article.body}
              </p>
            </article>
          ))}
        </div>
      )}
    </div>
  );
}
