import 'package:kelime_analiz_mobile/domain/profile/utils/username_utils.dart';
import 'package:kelime_analiz_mobile/domain/profile/models/player_profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kelime_analiz_mobile/domain/account/errors/email_verification_required_exception.dart';
import 'package:kelime_analiz_mobile/domain/account/repositories/account_repository.dart';

class AccountService implements AccountRepository {
  AccountService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;
  Future<void>? _googleSignInInitialization;

  Stream<User?> get authState => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  @override
  bool get currentUserNeedsEmailVerification {
    final user = _auth.currentUser;
    return user != null && _requiresEmailVerification(user);
  }

  @override
  bool get currentUserCanChangePassword {
    final user = _auth.currentUser;
    return user != null &&
        !user.isAnonymous &&
        user.email != null &&
        user.providerData.any((provider) => provider.providerId == 'password');
  }

  @override
  String? get currentUserEmail => _auth.currentUser?.email;

  @override
  Future<PlayerProfile?> loadCurrentProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    await user.reload();
    final refreshedUser = _auth.currentUser;
    if (refreshedUser == null) return null;

    if (_requiresEmailVerification(refreshedUser)) {
      return null;
    }

    return _ensurePlayerProfile(refreshedUser);
  }

  DocumentReference<Map<String, dynamic>> _legacyProfileRef(String username) =>
      _firestore.collection('rooms').doc(profileDocumentCode(username));

  Future<void> _syncLegacyGameProfile({
    required String playerId,
    required String username,
  }) {
    return _legacyProfileRef(username).set({
      'type': 'profile',
      'username': username,
      'usernameLower': username.toLowerCase(),
      'playerId': playerId,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<bool> isUsernameAvailable(String rawUsername) async {
    final username = normalizeUsername(rawUsername);
    _validateUsername(username);

    final usernameRef = _firestore
        .collection('usernames')
        .doc(profileDocumentCode(username));

    // Backend sıfırlandığı için kullanıcı adı için tek otorite
    // usernames koleksiyonudur. Eski /rooms/P... profil belgelerini
    // burada okumuyoruz.
    final usernameSnapshot = await usernameRef.get();
    return !usernameSnapshot.exists;
  }

  @override
  Future<PlayerProfile> changeUsername(String rawUsername) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Kullanıcı oturumu bulunamadı.');
    }

    final cleanName = normalizeUsername(rawUsername);
    _validateUsername(cleanName);

    final playerRef = _firestore.collection('players').doc(user.uid);
    final playerSnapshot = await playerRef.get();
    final currentUsername = (playerSnapshot.data()?['username'] as String?)
        ?.trim();

    if (currentUsername == null || currentUsername.isEmpty) {
      throw StateError('Mevcut kullanıcı adı bulunamadı.');
    }

    final oldKey = profileDocumentCode(currentUsername);
    final newKey = profileDocumentCode(cleanName);
    final oldUsernameRef = _firestore.collection('usernames').doc(oldKey);
    final newUsernameRef = _firestore.collection('usernames').doc(newKey);
    final oldLegacyRef = _legacyProfileRef(currentUsername);
    final newLegacyRef = _legacyProfileRef(cleanName);

    await _firestore.runTransaction((transaction) async {
      final newUsernameSnapshot = await transaction.get(newUsernameRef);
      if (newUsernameSnapshot.exists) {
        final owner = newUsernameSnapshot.data()?['playerId'] as String?;
        if (owner != user.uid) {
          throw StateError('Bu kullanıcı adı alınmış.');
        }
      }

      transaction.set(newUsernameRef, {
        'playerId': user.uid,
        'username': cleanName,
        'usernameLower': cleanName.toLowerCase(),
        'updatedAt': FieldValue.serverTimestamp(),
        if (!newUsernameSnapshot.exists)
          'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      transaction.set(playerRef, {
        'username': cleanName,
        'usernameLower': cleanName.toLowerCase(),
        // HarfArena'da görünen ad ve kullanıcı etiketi artık tek alan.
        'displayName': cleanName,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      transaction.set(newLegacyRef, {
        'type': 'profile',
        'username': cleanName,
        'usernameLower': cleanName.toLowerCase(),
        'playerId': user.uid,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (oldKey != newKey) {
        // Eski profil mirror belgesini silemiyoruz; username alanını yeni ada
        // çevirince eski kullanıcı adıyla yapılan arama artık eşleşmez.
        transaction.set(oldLegacyRef, {
          'type': 'profile',
          'username': cleanName,
          'usernameLower': cleanName.toLowerCase(),
          'playerId': user.uid,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        transaction.delete(oldUsernameRef);
      }
    });

    // Davet / membership / geçmiş kayıtları legacy profil alt koleksiyonunda.
    // Kullanıcı adı belge yolunu değiştirdiği için bu olayları yeni profile
    // kopyalıyoruz; böylece isim değişiminden sonra geçmiş kaybolmuyor.
    if (oldKey != newKey) {
      final oldEvents = await oldLegacyRef.collection('moves').get();
      for (var offset = 0; offset < oldEvents.docs.length; offset += 400) {
        final batch = _firestore.batch();
        final end = offset + 400 < oldEvents.docs.length
            ? offset + 400
            : oldEvents.docs.length;
        for (final document in oldEvents.docs.sublist(offset, end)) {
          final eventData = Map<String, dynamic>.from(document.data());
          if (eventData['action'] == 'invite_cancelled') continue;
          eventData['createdAt'] = FieldValue.serverTimestamp();
          batch.set(
            newLegacyRef.collection('moves').doc(document.id),
            eventData,
            SetOptions(merge: true),
          );
        }
        await batch.commit();
      }
    }

    if (!user.isAnonymous) {
      await user.updateDisplayName(cleanName);
    }

    return PlayerProfile(id: user.uid, username: cleanName);
  }

  @override
  Future<PlayerProfile> register({
    required String username,
    required String email,
    required String password,
  }) async {
    final cleanName = normalizeUsername(username);
    _validateUsername(cleanName);
    if (password.length < 6) {
      throw ArgumentError('Şifre en az 6 karakter olmalı.');
    }
    final usernameRef = _firestore
        .collection('usernames')
        .doc(profileDocumentCode(cleanName));

    if (!await isUsernameAvailable(cleanName)) {
      throw StateError('Bu kullanıcı adı alınmış.');
    }

    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user!;
    try {
      await _firestore.runTransaction((transaction) async {
        final playerRef = _firestore.collection('players').doc(user.uid);
        final legacyProfileRef = _legacyProfileRef(cleanName);

        // Kullanıcı adı tek kaynak olan usernames indexinden tekrar
        // kontrol edilir. Legacy profil belgesini okumak, belge henüz
        // yokken güvenli Firestore kurallarında permission-denied üretir.
        final usernameSnapshot = await transaction.get(usernameRef);

        if (usernameSnapshot.exists) {
          throw StateError('Bu kullanıcı adı alınmış.');
        }

        transaction.set(usernameRef, {
          'playerId': user.uid,
          'username': cleanName,
          'usernameLower': cleanName.toLowerCase(),
          'createdAt': FieldValue.serverTimestamp(),
        });
        transaction.set(playerRef, {
          'username': cleanName,
          'usernameLower': cleanName.toLowerCase(),
          'displayName': cleanName,
          'tagline': '',
          'settings': {
            'soundEffects': true,
            'vibration': true,
            'turnNotifications': true,
            'inviteNotifications': true,
            'resultNotifications': true,
            'defaultTurnDurationSeconds': 120,
            'theme': 'system',
          },
          'stats': {
            'totalGames': 0,
            'wins': 0,
            'losses': 0,
            'draws': 0,
            'totalScore': 0,
            'totalPlaySeconds': 0,
            'weeklyScore': 0,
            'xp': 0,
            'analysisAccuracyTotal': 0.0,
            'analyzedGames': 0,
            'winStreak': 0,
            'bestWinStreak': 0,
          },
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        transaction.set(legacyProfileRef, {
          'type': 'profile',
          'username': cleanName,
          'usernameLower': cleanName.toLowerCase(),
          'playerId': user.uid,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      });
      await user.updateDisplayName(cleanName);
    } catch (_) {
      await user.delete();
      rethrow;
    }

    // Hesap ve profil başarıyla oluşturulduktan sonra doğrulama mailini gönder.
    // Mail gönderimi geçici olarak başarısız olsa bile hesabı silmiyoruz;
    // doğrulama ekranındaki "Tekrar Gönder" butonu yeniden deneyebilir.
    try {
      await user.sendEmailVerification();
    } on FirebaseAuthException {
      // Verification screen handles resend.
    }

    return PlayerProfile(id: user.uid, username: cleanName);
  }

  @override
  Future<PlayerProfile> signIn({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();

    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
      throw ArgumentError('Geçerli bir e-posta adresi gir.');
    }

    if (password.length < 6) {
      throw ArgumentError('Şifre en az 6 karakter olmalı.');
    }

    final credential = await _auth.signInWithEmailAndPassword(
      email: cleanEmail,
      password: password,
    );

    final user = credential.user;
    if (user == null) {
      throw StateError('Oyuncu oturumu açılamadı.');
    }

    await user.reload();
    final refreshedUser = _auth.currentUser;

    if (refreshedUser == null) {
      throw StateError('Oyuncu oturumu açılamadı.');
    }

    if (_requiresEmailVerification(refreshedUser)) {
      throw EmailVerificationRequiredException(refreshedUser.email);
    }

    return _ensurePlayerProfile(refreshedUser);
  }

  @override
  Future<PlayerProfile> signInWithGoogle() async {
    if (kIsWeb) {
      final credential = await _auth.signInWithPopup(GoogleAuthProvider());
      final user = credential.user;
      if (user == null) throw StateError('Google hesabı açılamadı.');
      return _ensurePlayerProfile(user);
    }

    await (_googleSignInInitialization ??= _googleSignIn.initialize());
    final googleUser = await _googleSignIn.authenticate();
    final googleAuthentication = googleUser.authentication;
    final googleCredential = GoogleAuthProvider.credential(
      idToken: googleAuthentication.idToken,
    );
    final credential = await _auth.signInWithCredential(googleCredential);
    final user = credential.user;
    if (user == null) throw StateError('Google hesabı açılamadı.');
    return _ensurePlayerProfile(user);
  }

  @override
  Future<PlayerProfile> continueAsGuest() async {
    final current = _auth.currentUser;
    if (current != null) return _ensurePlayerProfile(current);
    final credential = await _auth.signInAnonymously();
    final user = credential.user;
    if (user == null) throw StateError('Misafir oturumu açılamadı.');
    return _ensurePlayerProfile(user);
  }

  @override
  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    final email = user?.email;
    if (user == null ||
        user.isAnonymous ||
        email == null ||
        !currentUserCanChangePassword) {
      throw StateError('Bu hesapta parola uygulama içinden değiştirilemiyor.');
    }
    if (currentPassword.isEmpty) {
      throw ArgumentError('Mevcut şifreni gir.');
    }
    if (newPassword.length < 6) {
      throw ArgumentError('Yeni şifre en az 6 karakter olmalı.');
    }

    await user.reauthenticateWithCredential(
      EmailAuthProvider.credential(email: email, password: currentPassword),
    );
    await user.updatePassword(newPassword);
  }

  @override
  Future<void> sendVerificationEmail() async {
    final user = _auth.currentUser;
    if (user == null || user.isAnonymous || user.emailVerified) {
      return;
    }

    await user.sendEmailVerification();
  }

  @override
  Future<PlayerProfile?> refreshVerifiedProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    await user.reload();
    final refreshedUser = _auth.currentUser;
    if (refreshedUser == null) return null;

    if (_requiresEmailVerification(refreshedUser)) {
      return null;
    }

    return _ensurePlayerProfile(refreshedUser);
  }

  @override
  Future<void> signOut() => _auth.signOut();

  Future<PlayerProfile> _ensurePlayerProfile(User user) async {
    final playerRef = _firestore.collection('players').doc(user.uid);
    final current = await playerRef.get();
    final currentData = current.data();
    final currentUsername = currentData?['username'] as String?;
    if (currentUsername != null && currentUsername.trim().isNotEmpty) {
      // E-posta yalnızca Firebase Authentication tarafında tutuluyor.
      // Eski refactor sürümlerinin players belgesine yazdığı e-postayı temizle.
      if (currentData != null && currentData.containsKey('email')) {
        await playerRef.update({
          'email': FieldValue.delete(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await _syncLegacyGameProfile(
        playerId: user.uid,
        username: currentUsername,
      );
      return PlayerProfile(id: user.uid, username: currentUsername);
    }

    final username = await _availableUsername(user);
    final usernameRef = _firestore
        .collection('usernames')
        .doc(profileDocumentCode(username));
    final legacyProfileRef = _legacyProfileRef(username);

    final ensuredUsername = await _firestore.runTransaction<String>((
      transaction,
    ) async {
      final existingPlayer = await transaction.get(playerRef);
      if (existingPlayer.exists) {
        final existingName = (existingPlayer.data()?['username'] as String?)
            ?.trim();
        if (existingName == null || existingName.isEmpty) {
          throw StateError('Oyuncu profili tamamlanamadı. Tekrar deneyin.');
        }
        return existingName;
      }

      final existingUsername = await transaction.get(usernameRef);
      if (existingUsername.exists) {
        throw StateError('Kullanıcı adı oluşturulamadı. Tekrar deneyin.');
      }

      transaction.set(usernameRef, {
        'playerId': user.uid,
        'username': username,
        'usernameLower': username.toLowerCase(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      transaction.set(playerRef, {
        'username': username,
        'usernameLower': username.toLowerCase(),
        'displayName': username,
        'tagline': '',
        'isGuest': user.isAnonymous,
        'settings': _defaultSettings,
        'stats': _defaultStats,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      transaction.set(legacyProfileRef, {
        'type': 'profile',
        'username': username,
        'usernameLower': username.toLowerCase(),
        'playerId': user.uid,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return username;
    });

    if (!user.isAnonymous && user.displayName != ensuredUsername) {
      await user.updateDisplayName(ensuredUsername);
    }
    return PlayerProfile(id: user.uid, username: ensuredUsername);
  }

  Future<String> _availableUsername(User user) async {
    final raw = user.isAnonymous
        ? 'Misafir_${user.uid.substring(0, 6)}'
        : (user.displayName ?? user.email?.split('@').first ?? 'Oyuncu');
    var base = normalizeUsername(raw)
        .replaceAll(RegExp(r'[^a-zA-ZçÇğĞıİöÖşŞüÜ0-9_]'), '');
    if (base.length < 3) base = 'Oyuncu';
    if (base.length > 12) base = base.substring(0, 12);

    for (var attempt = 0; attempt < 20; attempt++) {
      final suffix = attempt == 0 ? '' : '_${user.uid.substring(0, 3)}$attempt';
      final maxBaseLength = 16 - suffix.length;
      final candidate =
          '${base.substring(0, base.length.clamp(0, maxBaseLength))}$suffix';
      if (await isUsernameAvailable(candidate)) {
        return candidate;
      }
    }
    throw StateError('Kullanıcı adı oluşturulamadı. Tekrar deneyin.');
  }

  static const _defaultSettings = {
    'soundEffects': true,
    'vibration': true,
    'turnNotifications': true,
    'inviteNotifications': true,
    'resultNotifications': true,
    'defaultTurnDurationSeconds': 120,
    'theme': 'system',
  };

  static const _defaultStats = {
    'totalGames': 0,
    'wins': 0,
    'losses': 0,
    'draws': 0,
    'totalScore': 0,
    'totalPlaySeconds': 0,
    'weeklyScore': 0,
    'xp': 0,
    'analysisAccuracyTotal': 0.0,
    'analyzedGames': 0,
    'winStreak': 0,
    'bestWinStreak': 0,
  };

  static bool _requiresEmailVerification(User user) {
    return !user.isAnonymous &&
        user.email != null &&
        user.email!.isNotEmpty &&
        !user.emailVerified;
  }

  static void _validateUsername(String username) {
    if (!RegExp(r'^[a-zA-ZçÇğĞıİöÖşŞüÜ0-9_]{3,16}$').hasMatch(username)) {
      throw ArgumentError(
        'Kullanıcı adı 3-16 karakter olmalı; harf, sayı ve alt çizgi kullanılabilir.',
      );
    }
  }
}
