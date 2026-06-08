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
  const { data } = await supabase
    .from("schools")
    .select("id")
    .order("created_at", { ascending: true })
    .limit(1)
    .maybeSingle();
  return (data as { id: string } | null)?.id ?? null;
}

export async function getSchool(): Promise<School | null> {
  const schoolId = await getSchoolId();
  if (!schoolId) return null;
  const supabase = createSupabaseClient();
  const { data } = await supabase
    .from("schools")
    .select("*")
    .eq("id", schoolId)
    .maybeSingle();
  return data as School | null;
}

export async function getFaqs(): Promise<PortalFaq[]> {
  const schoolId = await getSchoolId();
  if (!schoolId) return [];
  const supabase = createSupabaseClient();
  const { data } = await supabase
    .from("portal_faqs")
    .select("*")
    .eq("school_id", schoolId)
    .eq("is_published", true)
    .order("sort_order");
  return (data ?? []) as PortalFaq[];
}

export async function getDownloads(): Promise<PortalDownload[]> {
  const schoolId = await getSchoolId();
  if (!schoolId) return [];
  const supabase = createSupabaseClient();
  const { data } = await supabase
    .from("portal_downloads")
    .select("*")
    .eq("school_id", schoolId)
    .eq("is_published", true)
    .order("created_at", { ascending: false });
  return data ?? [];
}

export async function getContacts(): Promise<PortalContact[]> {
  const schoolId = await getSchoolId();
  if (!schoolId) return [];
  const supabase = createSupabaseClient();
  const { data } = await supabase
    .from("portal_contacts")
    .select("*")
    .eq("school_id", schoolId)
    .eq("is_published", true)
    .order("sort_order");
  return data ?? [];
}

export async function getStories(): Promise<PortalStory[]> {
  const schoolId = await getSchoolId();
  if (!schoolId) return [];
  const supabase = createSupabaseClient();
  const { data } = await supabase
    .from("portal_success_stories")
    .select("*")
    .eq("school_id", schoolId)
    .eq("is_published", true)
    .order("created_at", { ascending: false });
  return data ?? [];
}

export async function getReviews(): Promise<PortalReview[]> {
  const schoolId = await getSchoolId();
  if (!schoolId) return [];
  const supabase = createSupabaseClient();
  const { data } = await supabase
    .from("portal_reviews")
    .select("*")
    .eq("school_id", schoolId)
    .eq("is_published", true)
    .order("created_at", { ascending: false });
  return data ?? [];
}

export async function getHelpArticles(): Promise<PortalHelp[]> {
  const schoolId = await getSchoolId();
  if (!schoolId) return [];
  const supabase = createSupabaseClient();
  const { data } = await supabase
    .from("portal_help_articles")
    .select("*")
    .eq("school_id", schoolId)
    .eq("is_published", true)
    .order("sort_order");
  return data ?? [];
}

export async function getGalleryPosts(): Promise<GalleryPost[]> {
  const schoolId = await getSchoolId();
  if (!schoolId) return [];
  const supabase = createSupabaseClient();
  const { data } = await supabase
    .from("gallery_posts")
    .select("*")
    .eq("school_id", schoolId)
    .eq("is_published", true)
    .order("created_at", { ascending: false });
  return data ?? [];
}

export async function getAppReleases(): Promise<AppRelease[]> {
  const schoolId = await getSchoolId();
  if (!schoolId) return [];
  const supabase = createSupabaseClient();
  const { data } = await supabase
    .from("portal_app_releases")
    .select("*")
    .eq("school_id", schoolId)
    .eq("is_enabled", true)
    .order("sort_order");
  return data ?? [];
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
