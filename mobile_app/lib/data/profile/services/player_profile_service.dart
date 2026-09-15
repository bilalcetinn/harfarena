import 'package:kelime_analiz_mobile/domain/profile/repositories/player_profile_repository.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kelime_analiz_mobile/domain/profile/models/player_profile.dart';
import 'package:kelime_analiz_mobile/domain/profile/models/player_invite.dart';
import 'package:kelime_analiz_mobile/domain/profile/models/match_history_entry.dart';
import 'package:kelime_analiz_mobile/domain/profile/utils/username_utils.dart';

class PlayerProfileService implements PlayerProfileRepository {
  PlayerProfileService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _providedFirestore = firestore,
      _providedAuth = auth;

  static const _idKey = 'player_id';
  static const _usernameKey = 'player_username';
  final FirebaseFirestore? _providedFirestore;
  final FirebaseAuth? _providedAuth;
  FirebaseFirestore get _firestore =>
      _providedFirestore ?? FirebaseFirestore.instance;
  FirebaseAuth get _auth => _providedAuth ?? FirebaseAuth.instance;

  @override
  Future<PlayerProfile?> load() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final snapshot = await _firestore.collection('players').doc(user.uid).get();
    final username = (snapshot.data()?['username'] as String?)?.trim();
    if (username == null || username.isEmpty) return null;
    return PlayerProfile(id: user.uid, username: username);
  }

  @override
  Future<void> logout() async {
    final preferences = await SharedPreferences.getInstance();
    await Future.wait<bool>([
      preferences.remove(_idKey),
      preferences.remove(_usernameKey),
    ]);
  }

  @override
  Future<PlayerProfile?> findByUsername(String rawUsername) async {
    final username = normalizeUsername(rawUsername);

    if (!RegExp(r'^[a-zA-ZçÇğĞıİöÖşŞüÜ0-9_]{3,16}$').hasMatch(username)) {
      return null;
    }

    final snapshot = await _firestore
        .collection('rooms')
        .doc(profileDocumentCode(username))
        .get();

    final data = snapshot.data();

    if (!snapshot.exists ||
        data?['type'] != 'profile' ||
        (data?['username'] as String?)?.toLowerCase() !=
            username.toLowerCase()) {
      return null;
    }

    final playerId = data?['playerId'] as String?;
    final canonicalUsername = data?['username'] as String?;

    if (playerId == null ||
        playerId.isEmpty ||
        canonicalUsername == null ||
        canonicalUsername.isEmpty) {
      return null;
    }

    return PlayerProfile(id: playerId, username: canonicalUsername);
  }

  @override
  Future<PlayerProfile> register(String rawUsername) async {
    final username = normalizeUsername(rawUsername);
    if (!RegExp(r'^[a-zA-ZçÇğĞıİöÖşŞüÜ0-9_]{3,16}$').hasMatch(username)) {
      throw ArgumentError(
        'Kullanıcı adı 3-16 karakter olmalı; harf, sayı ve alt çizgi kullanılabilir.',
      );
    }
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Kullanıcı oturumu bulunamadı.');
    }
    final id = user.uid;
    final ref = _firestore
        .collection('rooms')
        .doc(profileDocumentCode(username));
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      if (snapshot.exists) {
        final data = snapshot.data()!;
        if (data['type'] != 'profile') {
          throw StateError('Bu kullanıcı adı için başka bir ad dene.');
        }
        final existingName = data['username'] as String?;
        final existingId = data['playerId'] as String?;
        if (existingName != null &&
            existingName.toLowerCase() != username.toLowerCase()) {
          throw StateError('Bu kullanıcı adı için yeni bir ad dene.');
        }
        if (existingName?.toLowerCase() == username.toLowerCase() &&
            existingId != id) {
          throw StateError('Bu kullanıcı adı alınmış.');
        }
      }
      transaction.set(ref, {
        'type': 'profile',
        'username': username,
        'usernameLower': username.toLowerCase(),
        'playerId': id,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
    return PlayerProfile(id: id, username: username);
  }

  @override
  Future<void> sendInvite({
    required String targetUsername,
    required String roomCode,
    required String fromUsername,
  }) async {
    final normalized = normalizeUsername(targetUsername);
    if (normalized.isEmpty) throw ArgumentError('Rakibin kullanıcı adını yaz.');
    final profileRef = _firestore
        .collection('rooms')
        .doc(profileDocumentCode(normalized));
    final profile = await profileRef.get();
    if (!profile.exists ||
        profile.data()?['type'] != 'profile' ||
        (profile.data()?['username'] as String?)?.toLowerCase() !=
            normalized.toLowerCase()) {
      throw StateError('Bu kullanıcı bulunamadı.');
    }
    final sequence = DateTime.now().millisecondsSinceEpoch;
    await profileRef.collection('moves').doc('invite_$roomCode').set({
      'action': 'invite',
      'sequence': sequence,
      'roomCode': roomCode,
      'fromUsername': fromUsername,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Stream<List<PlayerInvite>> invitations(String username) =>
      _profileEvents(username, 'invite').map(
        (documents) => documents
            .map(
              (doc) => PlayerInvite(
                roomCode: doc.data()['roomCode'] as String,
                fromUsername: doc.data()['fromUsername'] as String,
                sequence: doc.data()['sequence'] as int,
                turnDurationSeconds:
                    doc.data()['turnDurationSeconds'] as int? ?? 90,
              ),
            )
            .toList(growable: false),
      );

  /// Append-only membership, invitation and history events keep every known
  /// room discoverable even when top-level collection queries are disallowed.
  @override
  Stream<Set<String>> roomCodes(String username) => _firestore
      .collection('rooms')
      .doc(profileDocumentCode(username))
      .collection('moves')
      .where('action', whereIn: ['membership', 'invite', 'history'])
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => doc.data()['roomCode'])
            .whereType<String>()
            .where((code) => code.length == 8)
            .toSet(),
      );

  @override
  Stream<List<MatchHistoryEntry>> history(String username) =>
      _profileEvents(username, 'history').map(
        (documents) => documents
            .map((doc) {
              final data = doc.data();
              return MatchHistoryEntry(
                roomCode: data['roomCode'] as String,
                hostName: data['hostName'] as String,
                guestName: data['guestName'] as String,
                hostScore: data['hostScore'] as int,
                guestScore: data['guestScore'] as int,
                sequence: data['sequence'] as int,
                winnerUid: data['winnerUid'] as String?,
              );
            })
            .toList(growable: false),
      );

  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _profileEvents(
    String username,
    String action,
  ) => _firestore
      .collection('rooms')
      .doc(profileDocumentCode(username))
      .collection('moves')
      .where('action', isEqualTo: action)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs.toList()
          ..sort(
            (a, b) => (b.data()['sequence'] as int).compareTo(
              a.data()['sequence'] as int,
            ),
          ),
      );
}
