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
  Future<void> signInWithMagicLink(String email) async {
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
