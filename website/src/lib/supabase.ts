import { createClient, type SupabaseClient } from "@supabase/supabase-js";
import { siteConfig } from "./config";

export function createSupabaseClient(): SupabaseClient | null {
  if (!siteConfig.supabaseUrl || !siteConfig.supabaseAnonKey) {
    return null;
  }
  return createClient(siteConfig.supabaseUrl, siteConfig.supabaseAnonKey);
}
