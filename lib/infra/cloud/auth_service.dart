import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static const String _redirectUrl = 'coupelaine://auth/callback';

  final SupabaseClient _supabase;

  AuthService(this._supabase);

  /// `true` si une session non-anonyme (email-based) est active.
  /// Une session anonyme (créée pour l'ORS proxy) n'est PAS un opt-in cloud.
  bool get isCloudOptedIn {
    final session = _supabase.auth.currentSession;
    return session != null && !session.user.isAnonymous;
  }

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  Session? get currentSession => _supabase.auth.currentSession;

  /// Envoie un magic link à l'email donné. Au clic dans l'email,
  /// l'app s'ouvre sur `coupelaine://auth/callback` et le SDK valide
  /// le token automatiquement.
  ///
  /// Si une session existe déjà (anonyme ou email), on signOut d'abord :
  /// `signInWithOtp` tente sinon une `linkIdentity` vers l'email donné,
  /// qui peut échouer (rate-limited, email déjà pris par un autre user,
  /// etc.). Le signOut garantit qu'on part d'une session vide.
  ///
  /// Conséquence : entre l'envoi du lien et le clic dans l'email,
  /// l'utilisateur n'a pas de session — l'ORS proxy ne fonctionnera pas
  /// pendant cette fenêtre. Le bootstrap de `main.dart` rouvre une
  /// session anonyme au prochain démarrage si l'utilisateur abandonne
  /// le flow.
  Future<void> signInWithMagicLink(String email) async {
    if (_supabase.auth.currentSession != null) {
      await _supabase.auth.signOut();
    }
    await _supabase.auth.signInWithOtp(
      email: email,
      emailRedirectTo: _redirectUrl,
    );
  }

  /// Déconnecte l'utilisateur du cloud puis rouvre une session anonyme
  /// pour que l'ORS proxy reste accessible.
  Future<void> signOut() async {
    await _supabase.auth.signOut();
    await _supabase.auth.signInAnonymously();
  }
}
