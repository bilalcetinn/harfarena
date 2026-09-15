import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:kelime_analiz_mobile/data/profile/models/leaderboard_entry_dto.dart';
import 'package:kelime_analiz_mobile/data/profile/models/player_backend_profile_dto.dart';
import 'package:kelime_analiz_mobile/data/profile/models/player_settings_dto.dart';
import 'package:kelime_analiz_mobile/domain/profile/models/leaderboard_entry.dart';
import 'package:kelime_analiz_mobile/domain/profile/models/player_backend_profile.dart';
import 'package:kelime_analiz_mobile/domain/profile/models/player_profile.dart';
import 'package:kelime_analiz_mobile/domain/profile/models/player_settings.dart';
import 'package:kelime_analiz_mobile/domain/profile/repositories/player_profile_details_repository.dart';
import 'package:kelime_analiz_mobile/domain/profile/utils/username_utils.dart';

/// Firestore data access used by the profile, settings and leaderboard screens.
///
/// Profil fotoğrafı Cloud Storage yerine küçük bir data URL olarak oyuncunun
/// Firestore belgesinde tutulur. Böylece Spark planda Firebase Storage'a
/// ihtiyaç kalmaz. Fotoğraf boyutu özellikle düşük tutulur; Firestore belge
/// limitine yaklaşmasına izin verilmez.
class PlayerBackendService implements PlayerProfileDetailsRepository {
  PlayerBackendService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static const int _maxAvatarBytes = 420 * 1024;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> playerRef(String playerId) =>
      _firestore.collection('players').doc(playerId);

  @override
  Stream<PlayerBackendProfile?> profile(String playerId) =>
      playerRef(playerId).snapshots().map(
        (snapshot) => snapshot.exists
            ? PlayerBackendProfileDto.fromMap(playerId, snapshot.data()!)
            : null,
      );

  @override
  Future<void> ensureProfile(PlayerProfile profile) async {
    final ref = playerRef(profile.id);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      if (snapshot.exists) {
        final data = snapshot.data();
        transaction.update(ref, {
          'username': profile.username,
          'usernameLower': normalizeUsername(profile.username).toLowerCase(),
          if ((data?['displayName'] as String?)?.trim().isEmpty ?? true)
            'displayName': profile.username,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return;
      }
      transaction.set(ref, {
        'username': profile.username,
        'usernameLower': normalizeUsername(profile.username).toLowerCase(),
        'displayName': profile.username,
        'tagline': '',
        'settings': PlayerSettingsDto.toMap(const PlayerSettings()),
        'stats': _emptyStats(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  @override
  Future<void> updatePublicProfile({
    required String playerId,
    required String displayName,
    String? avatarUrl,
  }) {
    final cleanDisplayName = displayName.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (cleanDisplayName.length < 3 || cleanDisplayName.length > 24) {
      throw ArgumentError('Kullanıcı adı 3-24 karakter olmalı.');
    }
    return playerRef(playerId).set({
      'displayName': cleanDisplayName,
      'avatarUrl': ?avatarUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<String> uploadAvatar({
    required String playerId,
    required Uint8List bytes,
    String contentType = 'image/jpeg',
  }) async {
    if (bytes.isEmpty) {
      throw ArgumentError('Profil fotoğrafı boş olamaz.');
    }
    if (bytes.lengthInBytes > _maxAvatarBytes) {
      throw ArgumentError(
        'Profil fotoğrafı çok büyük. Daha küçük bir fotoğraf seç.',
      );
    }

    final normalizedType = contentType.startsWith('image/')
        ? contentType
        : 'image/jpeg';
    final avatarDataUrl = 'data:$normalizedType;base64,${base64Encode(bytes)}';

    await playerRef(playerId).set({
      'avatarUrl': avatarDataUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return avatarDataUrl;
  }

  @override
  Future<void> updateSettings(String playerId, PlayerSettings settings) =>
      playerRef(playerId).set({
        'settings': PlayerSettingsDto.toMap(settings),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

  Future<void> recordAnalysis({
    required String playerId,
    required String roomCode,
    required double accuracy,
  }) async {
    if (accuracy < 0 || accuracy > 100) {
      throw ArgumentError('Analiz doğruluğu 0-100 arasında olmalı.');
    }
    final ref = playerRef(playerId);
    final marker = ref.collection('analyses').doc(roomCode);
    await _firestore.runTransaction((transaction) async {
      final player = await transaction.get(ref);
      final existing = await transaction.get(marker);
      if (existing.exists) return;
      final data = player.data() ?? const <String, dynamic>{};
      final oldStats =
          (data['stats'] as Map?)?.cast<String, dynamic>() ?? const {};
      transaction.set(ref, {
        'stats': {
          ...oldStats,
          'analysisAccuracyTotal':
              (oldStats['analysisAccuracyTotal'] as num? ?? 0).toDouble() +
              accuracy,
          'analyzedGames': (oldStats['analyzedGames'] as int? ?? 0) + 1,
        },
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      transaction.set(marker, {
        'roomCode': roomCode,
        'accuracy': accuracy,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Stream<List<LeaderboardEntry>> leaderboard({
    required bool weekly,
    int limit = 100,
  }) => _firestore
      .collection(weekly ? 'leaderboard_weekly' : 'leaderboard_all_time')
      .orderBy('score', descending: true)
      .limit(limit.clamp(1, 100))
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map(LeaderboardEntryDto.fromDocument)
            .toList(growable: false),
      );

  static Map<String, dynamic> _emptyStats() => {
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
}
