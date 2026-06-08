import { createClient } from "@supabase/supabase-js";
import { siteConfig } from "./config";

export function createSupabaseClient() {
  if (!siteConfig.supabaseUrl || !siteConfig.supabaseAnonKey) {
    throw new Error(
      "Missing NEXT_PUBLIC_SUPABASE_URL or NEXT_PUBLIC_SUPABASE_ANON_KEY",
    );
  }
  return createClient(siteConfig.supabaseUrl, siteConfig.supabaseAnonKey);
}
