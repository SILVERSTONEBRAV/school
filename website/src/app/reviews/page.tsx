import { ReviewForm } from "@/components/ReviewForm";
import { getReviews } from "@/lib/data";

function Stars({ count }: { count: number }) {
  return (
    <span className="text-amber-500" aria-label={`${count} stars`}>
      {"★".repeat(count)}
      <span className="text-slate-300">{"★".repeat(5 - count)}</span>
    </span>
  );
}

export default async function ReviewsPage() {
  const reviews = await getReviews();

  return (
    <div className="container-page py-16">
      <h1 className="section-title">Reviews</h1>
      <p className="section-lead">
        What parents, students, and alumni say about our school.
      </p>

      <div className="mt-10 grid gap-8 lg:grid-cols-2">
        <div className="space-y-4">
          {reviews.length === 0 ? (
            <p className="text-slate-600">No published reviews yet.</p>
          ) : (
            reviews.map((review) => (
              <div key={review.id} className="card">
                <div className="flex items-center justify-between gap-4">
                  <div>
                    <p className="font-semibold">{review.reviewer_name}</p>
                    {review.reviewer_role && (
                      <p className="text-sm text-slate-500">
                        {review.reviewer_role}
                      </p>
                    )}
                  </div>
                  <Stars count={review.rating} />
                </div>
                <p className="mt-3 text-slate-700">{review.body}</p>
              </div>
            ))
          )}
        </div>
        <ReviewForm />
      </div>
    </div>
  );
}
