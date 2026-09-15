import 'package:kelime_analiz_mobile/domain/profile/models/player_profile.dart';

abstract interface class AccountRepository {
  bool get currentUserNeedsEmailVerification;
  bool get currentUserCanChangePassword;
  String? get currentUserEmail;

  Future<PlayerProfile?> loadCurrentProfile();
  Future<bool> isUsernameAvailable(String username);
  Future<PlayerProfile> changeUsername(String username);
  Future<PlayerProfile> register({
    required String username,
    required String email,
    required String password,
  });
  Future<PlayerProfile> signIn({
    required String email,
    required String password,
  });
  Future<PlayerProfile> signInWithGoogle();
  Future<PlayerProfile> continueAsGuest();
  Future<void> sendPasswordReset(String email);
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });
  Future<void> sendVerificationEmail();
  Future<PlayerProfile?> refreshVerifiedProfile();
  Future<void> signOut();
}
