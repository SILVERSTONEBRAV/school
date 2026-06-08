import { createSupabaseClient } from "./supabase";
import { siteConfig } from "./config";
import type {
  AppRelease,
  GalleryPost,
  PortalContact,
  PortalDownload,
  PortalFaq,
  PortalHelp,
  PortalReview,
  PortalStory,
  School,
} from "./types";

async function getSchoolId(): Promise<string | null> {
  if (siteConfig.schoolId) return siteConfig.schoolId;

  const supabase = createSupabaseClient();
  if (!supabase) return null;

  try {
    const { data, error } = await supabase
      .from("schools")
      .select("id")
      .order("created_at", { ascending: true })
      .limit(1)
      .maybeSingle();

    if (error) {
      console.error("getSchoolId:", error.message);
      return null;
    }

    return (data as { id: string } | null)?.id ?? null;
  } catch (e) {
    console.error("getSchoolId:", e);
    return null;
  }
}

export async function getSchool(): Promise<School | null> {
  const schoolId = await getSchoolId();
  if (!schoolId) return null;

  const supabase = createSupabaseClient();
  if (!supabase) return null;

  try {
    const { data, error } = await supabase
      .from("schools")
      .select("*")
      .eq("id", schoolId)
      .maybeSingle();

    if (error) {
      console.error("getSchool:", error.message);
      return null;
    }

    return data as School | null;
  } catch (e) {
    console.error("getSchool:", e);
    return null;
  }
}

async function fetchPublished<T>(
  table: string,
  schoolId: string,
  order: { column: string; ascending?: boolean },
): Promise<T[]> {
  const supabase = createSupabaseClient();
  if (!supabase) return [];

  try {
    const query = supabase
      .from(table)
      .select("*")
      .eq("school_id", schoolId)
      .eq("is_published", true)
      .order(order.column, { ascending: order.ascending ?? true });

    const { data, error } = await query;
    if (error) {
      console.error(`fetchPublished ${table}:`, error.message);
      return [];
    }
    return (data ?? []) as T[];
  } catch (e) {
    console.error(`fetchPublished ${table}:`, e);
    return [];
  }
}

export async function getFaqs(): Promise<PortalFaq[]> {
  const schoolId = await getSchoolId();
  if (!schoolId) return [];
  return fetchPublished<PortalFaq>("portal_faqs", schoolId, {
    column: "sort_order",
  });
}

export async function getDownloads(): Promise<PortalDownload[]> {
  const schoolId = await getSchoolId();
  if (!schoolId) return [];
  return fetchPublished<PortalDownload>("portal_downloads", schoolId, {
    column: "created_at",
    ascending: false,
  });
}

export async function getContacts(): Promise<PortalContact[]> {
  const schoolId = await getSchoolId();
  if (!schoolId) return [];
  return fetchPublished<PortalContact>("portal_contacts", schoolId, {
    column: "sort_order",
  });
}

export async function getStories(): Promise<PortalStory[]> {
  const schoolId = await getSchoolId();
  if (!schoolId) return [];
  return fetchPublished<PortalStory>("portal_success_stories", schoolId, {
    column: "created_at",
    ascending: false,
  });
}

export async function getReviews(): Promise<PortalReview[]> {
  const schoolId = await getSchoolId();
  if (!schoolId) return [];
  return fetchPublished<PortalReview>("portal_reviews", schoolId, {
    column: "created_at",
    ascending: false,
  });
}

export async function getHelpArticles(): Promise<PortalHelp[]> {
  const schoolId = await getSchoolId();
  if (!schoolId) return [];
  return fetchPublished<PortalHelp>("portal_help_articles", schoolId, {
    column: "sort_order",
  });
}

export async function getGalleryPosts(): Promise<GalleryPost[]> {
  const schoolId = await getSchoolId();
  if (!schoolId) return [];
  return fetchPublished<GalleryPost>("gallery_posts", schoolId, {
    column: "created_at",
    ascending: false,
  });
}

export async function getAppReleases(): Promise<AppRelease[]> {
  const schoolId = await getSchoolId();
  if (!schoolId) return [];

  const supabase = createSupabaseClient();
  if (!supabase) return [];

  try {
    const { data, error } = await supabase
      .from("portal_app_releases")
      .select("*")
      .eq("school_id", schoolId)
      .eq("is_enabled", true)
      .order("sort_order");

    if (error) {
      console.error("getAppReleases:", error.message);
      return [];
    }

    return (data ?? []) as AppRelease[];
  } catch (e) {
    console.error("getAppReleases:", e);
    return [];
  }
}

export async function submitReview(input: {
  reviewerName: string;
  reviewerRole?: string;
  rating: number;
  body: string;
}) {
  const schoolId = await getSchoolId();
  if (!schoolId) throw new Error("School not configured");

  const supabase = createSupabaseClient();
  if (!supabase) {
    throw new Error("Supabase is not configured on the server");
  }

  const { error } = await supabase.from("portal_reviews").insert({
    school_id: schoolId,
    reviewer_name: input.reviewerName,
    reviewer_role: input.reviewerRole ?? null,
    rating: input.rating,
    body: input.body,
    is_published: false,
  });

  if (error) throw error;
}
