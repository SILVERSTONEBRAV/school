import Link from "next/link";
import { getFaqs } from "@/lib/data";

export default async function FaqsPage() {
  const faqs = await getFaqs();
  const categories = [...new Set(faqs.map((f) => f.category ?? "General"))];

  return (
    <div className="container-page py-16">
      <h1 className="section-title">FAQs</h1>
      <p className="section-lead">
        Frequently asked questions. Need more help? Visit our{" "}
        <Link href="/help" className="text-brand-600 underline">
          help center
        </Link>
        .
      </p>

      {faqs.length === 0 ? (
        <p className="mt-10 text-slate-600">No FAQs published yet.</p>
      ) : (
        <div className="mt-10 space-y-10">
          {categories.map((category) => (
            <section key={category}>
              <h2 className="text-lg font-semibold text-brand-700">{category}</h2>
              <div className="mt-4 space-y-3">
                {faqs
                  .filter((f) => (f.category ?? "General") === category)
                  .map((faq) => (
                    <details key={faq.id} className="card group">
                      <summary className="cursor-pointer font-medium text-slate-900">
                        {faq.question}
                      </summary>
                      <p className="mt-3 whitespace-pre-wrap text-slate-700">
                        {faq.answer}
                      </p>
                    </details>
                  ))}
              </div>
            </section>
          ))}
        </div>
      )}
    </div>
  );
}
