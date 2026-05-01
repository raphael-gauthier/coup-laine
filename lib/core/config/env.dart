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

  /// Stub temporaire — sera supprimé en T12 quand `OrsRoutingService` sera
  /// migré vers l'Edge Function `ors-proxy` (plus besoin de clé côté client).
  /// Conserver pour que `lib/state/providers.dart` continue de compiler entre
  /// les commits T9 et T12. La valeur vide n'est jamais utilisée — un appel
  /// ORS direct échouerait au runtime, mais T12 retire cette dépendance.
  @Deprecated('Removed in T12 — use ors-proxy Edge Function instead')
  static const String orsApiKey = '';
}
