import Image from "next/image";
import { siteConfig } from "@/lib/config";
import { getGalleryPosts } from "@/lib/data";

export default async function GalleryPage() {
  const posts = await getGalleryPosts();

  return (
    <div className="container-page py-16">
      <h1 className="section-title">Gallery</h1>
      <p className="section-lead">
        Campus life, events, and community moments. Sign in to the app to like and
        comment.
      </p>

      {posts.length === 0 ? (
        <p className="mt-10 text-slate-600">No photos published yet.</p>
      ) : (
        <div className="mt-10 grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-4">
          {posts.map((post) => (
            <figure
              key={post.id}
              className="group overflow-hidden rounded-xl border border-slate-200 bg-white"
            >
              <div className="relative aspect-square">
                <Image
                  src={post.image_url}
                  alt={post.caption ?? "Gallery photo"}
                  fill
                  className="object-cover transition group-hover:scale-105"
                />
              </div>
              {post.caption && (
                <figcaption className="p-3 text-sm text-slate-600">
                  {post.caption}
                </figcaption>
              )}
            </figure>
          ))}
        </div>
      )}

      <div className="mt-10 card bg-brand-50">
        <p className="font-medium text-brand-900">Want to engage?</p>
        <p className="mt-1 text-sm text-brand-800">
          Parents can like and comment on photos inside the mobile or desktop app.
        </p>
        <a href={`${siteConfig.appUrl}/login`} className="btn-primary mt-4 inline-flex">
          Sign in to app
        </a>
      </div>
    </div>
  );
}
