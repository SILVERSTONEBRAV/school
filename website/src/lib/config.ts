export const siteConfig = {
  appUrl: process.env.NEXT_PUBLIC_APP_URL ?? "http://localhost:8080",
  supabaseUrl: process.env.NEXT_PUBLIC_SUPABASE_URL ?? "",
  supabaseAnonKey: process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY ?? "",
  schoolId: process.env.NEXT_PUBLIC_SCHOOL_ID,
};
