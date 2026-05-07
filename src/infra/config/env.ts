function required(name: string, value: string | undefined): string {
  if (!value || value.length === 0) {
    throw new Error(`Missing env var: ${name}`);
  }
  return value;
}

export const env = {
  supabaseUrl: required('EXPO_PUBLIC_SUPABASE_URL', process.env.EXPO_PUBLIC_SUPABASE_URL),
  supabaseAnonKey: required('EXPO_PUBLIC_SUPABASE_ANON_KEY', process.env.EXPO_PUBLIC_SUPABASE_ANON_KEY),
  maptilerApiKey: required('EXPO_PUBLIC_MAPTILER_API_KEY', process.env.EXPO_PUBLIC_MAPTILER_API_KEY),
  orsBaseUrl: required('EXPO_PUBLIC_ORS_BASE_URL', process.env.EXPO_PUBLIC_ORS_BASE_URL),
};
