/// Configuration globale au build.
///
/// Les valeurs Supabase (URL projet + clé anonyme) sont publiques par design
/// — elles identifient le projet mais ne donnent aucun accès par elles-mêmes.
/// L'accès est gaté par l'auth utilisateur + Row-Level Security.
///
/// Voir `docs/superpowers/specs/2026-05-01-cloud-sync-design.md` §7.3.
class Env {
  Env._();

  /// URL du projet Supabase.
  static const String supabaseUrl = 'https://zsrzheuxxkpvuezojwlg.supabase.co';

  /// Clé anonyme publique du projet Supabase.
  static const String supabaseAnonKey =
      'sb_publishable_LmKB9g7xyOA3ZsSZP-jsOA_pdgKSS0s';
}
