export type School = {
  id: string;
  name: string;
  logo_url: string | null;
  motto: string | null;
  tagline: string | null;
  mission: string | null;
  vision: string | null;
  about: string | null;
  address: string | null;
  phone: string | null;
  email: string | null;
  website: string | null;
  map_url: string | null;
  established_year: number | null;
  created_at: string;
};

export type PortalFaq = {
  id: string;
  question: string;
  answer: string;
  category: string | null;
  sort_order: number;
};

export type PortalDownload = {
  id: string;
  title: string;
  description: string | null;
  file_url: string;
  category: string | null;
  created_at: string;
};

export type PortalContact = {
  id: string;
  department: string;
  contact_name: string | null;
  email: string | null;
  phone: string | null;
};

export type PortalStory = {
  id: string;
  title: string;
  body: string;
  image_url: string | null;
  author_name: string | null;
  created_at: string;
};

export type PortalReview = {
  id: string;
  reviewer_name: string;
  reviewer_role: string | null;
  rating: number;
  body: string;
  created_at: string;
};

export type PortalHelp = {
  id: string;
  title: string;
  body: string;
  category: string | null;
  sort_order: number;
};

export type GalleryPost = {
  id: string;
  caption: string | null;
  image_url: string;
  created_at: string;
};

export type AppRelease = {
  id: string;
  platform: "web" | "windows" | "android" | "ios";
  download_url: string | null;
  version: string | null;
  release_notes: string | null;
  is_enabled: boolean;
  sort_order: number;
};

export type Database = {
  public: {
    Tables: {
      schools: { Row: School };
      portal_faqs: { Row: PortalFaq };
      portal_downloads: { Row: PortalDownload };
      portal_contacts: { Row: PortalContact };
      portal_success_stories: { Row: PortalStory };
      portal_reviews: { Row: PortalReview };
      portal_help_articles: { Row: PortalHelp };
      gallery_posts: { Row: GalleryPost };
      portal_app_releases: { Row: AppRelease };
    };
  };
};
