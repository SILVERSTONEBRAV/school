import Image from "next/image";
import { getStories } from "@/lib/data";

export default async function StoriesPage() {
  const stories = await getStories();

  return (
    <div className="container-page py-16">
      <h1 className="section-title">Success stories</h1>
      <p className="section-lead">
        Celebrating achievements from our students and alumni.
      </p>

      {stories.length === 0 ? (
        <p className="mt-10 text-slate-600">No stories published yet.</p>
      ) : (
        <div className="mt-10 grid gap-6 md:grid-cols-2">
          {stories.map((story) => (
            <article key={story.id} className="card overflow-hidden p-0">
              {story.image_url && (
                <div className="relative h-48 w-full">
                  <Image
                    src={story.image_url}
                    alt={story.title}
                    fill
                    className="object-cover"
                  />
                </div>
              )}
              <div className="p-6">
                <h2 className="text-xl font-semibold">{story.title}</h2>
                {story.author_name && (
                  <p className="mt-1 text-sm text-slate-500">{story.author_name}</p>
                )}
                <p className="mt-3 whitespace-pre-wrap text-slate-700">
                  {story.body}
                </p>
              </div>
            </article>
          ))}
        </div>
      )}
    </div>
  );
}
