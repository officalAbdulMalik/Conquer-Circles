import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GoogleAuthService {
  GoogleAuthService(this._client);

  final SupabaseClient _client;
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  Future<void> signIn({required String oauthCallbackUrl}) async {
    if (kIsWeb ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      await _signInWithOAuth(oauthCallbackUrl);
      return;
    }

    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw const AuthException('Google sign-in was cancelled.');
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null || idToken.isEmpty) {
        await _signInWithOAuth(oauthCallbackUrl);
        return;
      }

      await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: googleAuth.accessToken,
      );
    } on AuthException {
      rethrow;
    } catch (_) {
      await _signInWithOAuth(oauthCallbackUrl);
    }
  }

  Future<void> _signInWithOAuth(String oauthCallbackUrl) {
    return _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: oauthCallbackUrl,
    );
  }
}
