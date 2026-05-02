import 'package:coup_laine/infra/cloud/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockSupabase extends Mock implements SupabaseClient {}

class _MockAuth extends Mock implements GoTrueClient {}

void main() {
  late _MockSupabase supabase;
  late _MockAuth auth;
  late AuthService service;

  setUp(() {
    supabase = _MockSupabase();
    auth = _MockAuth();
    when(() => supabase.auth).thenReturn(auth);
    service = AuthService(supabase);
  });

  group('isCloudOptedIn', () {
    test('returns false when no session', () {
      when(() => auth.currentSession).thenReturn(null);
      expect(service.isCloudOptedIn, isFalse);
    });

    test('returns false for anonymous session', () {
      final user = User(
        id: 'u1',
        appMetadata: const {},
        userMetadata: null,
        aud: 'authenticated',
        createdAt: '2026-01-01T00:00:00Z',
        isAnonymous: true,
      );
      when(() => auth.currentSession).thenReturn(_fakeSession(user));
      expect(service.isCloudOptedIn, isFalse);
    });

    test('returns true for email session', () {
      final user = User(
        id: 'u1',
        appMetadata: const {},
        userMetadata: null,
        aud: 'authenticated',
        createdAt: '2026-01-01T00:00:00Z',
        isAnonymous: false,
        email: 'a@b.fr',
      );
      when(() => auth.currentSession).thenReturn(_fakeSession(user));
      expect(service.isCloudOptedIn, isTrue);
    });
  });

  group('signInWithMagicLink', () {
    test('sans session existante : appelle signInWithOtp directement', () async {
      when(() => auth.currentSession).thenReturn(null);
      when(() => auth.signInWithOtp(
            email: any(named: 'email'),
            emailRedirectTo: any(named: 'emailRedirectTo'),
          )).thenAnswer((_) async {});

      await service.signInWithMagicLink('user@example.com');

      verifyNever(() => auth.signOut());
      verify(() => auth.signInWithOtp(
            email: 'user@example.com',
            emailRedirectTo: 'coupelaine://auth/callback',
          )).called(1);
    });

    test(
        'avec session existante (anon) : signOut puis signInWithOtp pour éviter linkIdentity',
        () async {
      final anonUser = User(
        id: 'u1',
        appMetadata: const {},
        userMetadata: null,
        aud: 'authenticated',
        createdAt: '2026-01-01T00:00:00Z',
        isAnonymous: true,
      );
      when(() => auth.currentSession).thenReturn(_fakeSession(anonUser));
      when(() => auth.signOut()).thenAnswer((_) async {});
      when(() => auth.signInWithOtp(
            email: any(named: 'email'),
            emailRedirectTo: any(named: 'emailRedirectTo'),
          )).thenAnswer((_) async {});

      await service.signInWithMagicLink('user@example.com');

      verifyInOrder([
        () => auth.signOut(),
        () => auth.signInWithOtp(
              email: 'user@example.com',
              emailRedirectTo: 'coupelaine://auth/callback',
            ),
      ]);
    });
  });

  group('signOut', () {
    test('signOut puis signInAnonymously', () async {
      when(() => auth.signOut()).thenAnswer((_) async {});
      when(() => auth.signInAnonymously())
          .thenAnswer((_) async => AuthResponse());

      await service.signOut();

      verifyInOrder([
        () => auth.signOut(),
        () => auth.signInAnonymously(),
      ]);
    });
  });
}

Session _fakeSession(User user) => Session(
      accessToken: 'tok',
      tokenType: 'bearer',
      user: user,
    );
