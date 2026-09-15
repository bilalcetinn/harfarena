import 'package:kelime_analiz_mobile/domain/gameplay/repositories/online_game_repository.dart';
import 'package:kelime_analiz_mobile/domain/profile/utils/username_utils.dart';

import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:turkish_word_engine/turkish_word_engine.dart';

import 'package:kelime_analiz_mobile/domain/gameplay/constants/game_time_control.dart';
import 'package:kelime_analiz_mobile/data/profile/services/player_profile_service.dart';

import 'package:kelime_analiz_mobile/domain/gameplay/models/online_move.dart';
import 'package:kelime_analiz_mobile/data/gameplay/models/online_move_dto.dart';
import 'package:kelime_analiz_mobile/domain/gameplay/models/online_room.dart';
import 'package:kelime_analiz_mobile/data/gameplay/models/online_room_dto.dart';

class OnlineGameService implements OnlineGameRepository {
  factory OnlineGameService({
    required String playerId,
    required String playerName,
    FirebaseFirestore? firestore,
    DateTime Function()? clock,
  }) => OnlineGameService._(
    firestore ?? FirebaseFirestore.instance,
    playerId,
    playerName,
    clock ?? DateTime.now,
  );

  OnlineGameService._(
    this._firestore,
    this._playerId,
    this._playerName,
    this._clock,
  );

  final FirebaseFirestore _firestore;
  final Random _random = Random.secure();
  final String _playerId;
  final String _playerName;
  final DateTime Function() _clock;

  @override
  String get currentUid => _playerId;

  DocumentReference<Map<String, dynamic>> _profileRef(String username) =>
      _firestore.collection('rooms').doc(profileDocumentCode(username));

  DocumentReference<Map<String, dynamic>> _membershipRef(
    String username,
    String code,
  ) => _profileRef(username).collection('moves').doc('membership_$code');

  Map<String, dynamic> _membership(String roomCode) => {
    'action': 'membership',
    'sequence': _clock().millisecondsSinceEpoch,
    'roomCode': roomCode,
    'createdAt': FieldValue.serverTimestamp(),
  };

  @override
  Future<OnlineRoom> createRoom({
    int turnDurationSeconds = kDefaultTurnDurationSeconds,
    String? targetUsername,
  }) async {
    if (!kTurnDurationOptions.contains(turnDurationSeconds)) {
      throw ArgumentError('Geçerli bir hamle süresi seç.');
    }

    final targetName = targetUsername == null
        ? null
        : normalizeUsername(targetUsername);

    if (targetName != null && targetName.isEmpty) {
      throw ArgumentError('Rakibin kullanıcı adını yaz.');
    }

    for (var attempt = 0; attempt < 8; attempt++) {
      const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
      final code = List.generate(
        8,
        (_) => alphabet[_random.nextInt(alphabet.length)],
      ).join();

      final roomRef = _firestore.collection('rooms').doc(code);
      Map<String, dynamic>? targetData;

      final created = await _firestore.runTransaction((transaction) async {
        final existing = await transaction.get(roomRef);
        if (existing.exists) return false;

        if (targetName != null) {
          final target = await transaction.get(_profileRef(targetName));
          targetData = target.data();

          if (targetData?['type'] != 'profile' ||
              (targetData?['username'] as String?)?.toLowerCase() !=
                  targetName.toLowerCase()) {
            throw StateError('Bu kullanıcı bulunamadı.');
          }

          if (targetData!['playerId'] == _playerId) {
            throw StateError('Kendine maç daveti gönderemezsin.');
          }
        }

        transaction.set(roomRef, {
          'type': 'match',
          'hostUid': _playerId,
          'hostName': _playerName,
          'guestUid': null,
          'guestName': null,
          'invitedGuestUid': targetData?['playerId'],
          'invitedGuestName': targetData?['username'],
          'turnUid': _playerId,
          'status': 'waiting',
          'seed': _random.nextInt(1 << 31),
          'moveCount': 0,
          'turnDurationSeconds': turnDurationSeconds,
          'turnStartedAt': null,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'lastMoveId': null,
        });

        transaction.set(_membershipRef(_playerName, code), _membership(code));

        if (targetData != null) {
          final targetUsername = targetData!['username'] as String;
          transaction.set(
            _membershipRef(targetUsername, code),
            _membership(code),
          );
          transaction.set(
            _profileRef(targetUsername).collection('moves').doc('invite_$code'),
            {
              'action': 'invite',
              'sequence': _clock().millisecondsSinceEpoch,
              'roomCode': code,
              'fromUsername': _playerName,
              'turnDurationSeconds': turnDurationSeconds,
              'createdAt': FieldValue.serverTimestamp(),
            },
          );
        }

        return true;
      });

      if (!created) continue;

      final createdRoom = await roomRef.get();
      if (!OnlineRoomDto.isRoomData(createdRoom.data())) {
        throw StateError('Oda oluşturulamadı.');
      }
      return OnlineRoomDto.fromSnapshot(createdRoom);
    }

    throw StateError('Uygun oda kodu üretilemedi.');
  }

  @override
  Future<void> cancelInvitation(OnlineRoom room) async {
    final roomRef = _firestore.collection('rooms').doc(room.code);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(roomRef);

      if (!OnlineRoomDto.isRoomData(snapshot.data())) {
        throw StateError('Oda bulunamadı.');
      }

      final current = OnlineRoomDto.fromSnapshot(snapshot);

      if (current.hostUid != _playerId) {
        throw StateError('Bu daveti yalnızca gönderen oyuncu iptal edebilir.');
      }

      if (current.isCancelled) return;

      if (current.status != 'waiting' || current.guestUid != null) {
        throw StateError('Başlamış bir maç davet olarak iptal edilemez.');
      }

      transaction.update(roomRef, {
        'status': 'cancelled',
        'invitedGuestUid': null,
        'invitedGuestName': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final invitedGuestName = current.invitedGuestName;
      if (invitedGuestName != null && invitedGuestName.isNotEmpty) {
        final inviteRef = _profileRef(invitedGuestName)
            .collection('moves')
            .doc('invite_${room.code}');

        // Rakibin event belgesini okumak güvenlik kuralları tarafından
        // engellenebilir. merge set ile hem var olan kaydı güncelliyor hem de
        // belge eksikse güvenli şekilde kapatılmış bir event oluşturuyoruz.
        transaction.set(inviteRef, {
          'action': 'invite_cancelled',
          'roomCode': room.code,
          'cancelledAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    });
  }

  @override
  Future<OnlineRoom> joinRoom(String rawCode) async {
    final code = rawCode.trim().toUpperCase();
    if (!RegExp(r'^[ABCDEFGHJKLMNPQRSTUVWXYZ23456789]{8}$').hasMatch(code)) {
      throw ArgumentError('Oda kodu 8 karakter olmalı.');
    }
    final ref = _firestore.collection('rooms').doc(code);
    await _firestore.runTransaction((transaction) async {
      final snap = await transaction.get(ref);
      if (!OnlineRoomDto.isRoomData(snap.data())) {
        throw StateError('Oda bulunamadı.');
      }
      final data = snap.data()!;
      final hostUid = data['hostUid'] as String;
      final guestUid = data['guestUid'] as String?;
      final isMember = hostUid == _playerId || guestUid == _playerId;
      if (!isMember) {
        if (data['status'] != 'waiting') {
          throw StateError('Bu maça artık katılınamaz.');
        }
        if (guestUid != null) throw StateError('Bu oda dolu.');
        final invitedUid = data['invitedGuestUid'] as String?;
        if (invitedUid != null && invitedUid != _playerId) {
          throw StateError('Bu davet başka bir oyuncuya gönderilmiş.');
        }
      }
      final membershipRef = _membershipRef(_playerName, code);
      final membership = await transaction.get(membershipRef);
      if (!membership.exists) {
        transaction.set(membershipRef, _membership(code));
      }
      if (isMember) return;
      transaction.update(ref, {
        'guestUid': _playerId,
        'guestName': _playerName,
        'status': 'playing',
        'startedAt': FieldValue.serverTimestamp(),
        'turnStartedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
    final joinedRoom = await ref.get();
    if (!OnlineRoomDto.isRoomData(joinedRoom.data())) {
      throw StateError('Oda artık mevcut değil.');
    }
    return OnlineRoomDto.fromSnapshot(joinedRoom);
  }

  @override
  Stream<OnlineRoom?> room(String code) => _firestore
      .collection('rooms')
      .doc(code)
      .snapshots()
      .map(
        (snap) => OnlineRoomDto.isRoomData(snap.data())
            ? OnlineRoomDto.fromSnapshot(snap)
            : null,
      );

  /// Membership events survive app restarts and work with the fixed-document
  /// rules of the prototype without querying the entire rooms collection.
  @override
  Stream<List<OnlineRoom>> myRooms() {
    late StreamController<List<OnlineRoom>> controller;
    final subscriptions = <StreamSubscription<dynamic>>[];
    final watchedCodes = <String>{};
    final rooms = <String, OnlineRoom>{};
    var cancelled = false;

    void emit() {
      if (cancelled) return;
      final result = rooms.values.toList()
        ..sort((a, b) {
          final dateOrder = (b.updatedAt ?? DateTime(1970)).compareTo(
            a.updatedAt ?? DateTime(1970),
          );
          return dateOrder == 0 ? a.code.compareTo(b.code) : dateOrder;
        });
      controller.add(List<OnlineRoom>.unmodifiable(result));
    }

    void reportError(Object error, StackTrace stackTrace) {
      if (!cancelled) controller.addError(error, stackTrace);
    }

    void watchRoom(String code) {
      if (cancelled || code.length != 8 || !watchedCodes.add(code)) return;
      subscriptions.add(
        room(code).listen(
          (value) {
            if (value != null &&
                (value.hostUid == _playerId ||
                    value.guestUid == _playerId ||
                    value.invitedGuestUid == _playerId)) {
              rooms[code] = value;
            } else {
              rooms.remove(code);
            }
            emit();
          },
          onError: (Object error, StackTrace stackTrace) {
            if (error is FirebaseException &&
                error.code == 'permission-denied') {
              rooms.remove(code);
              emit();
              return;
            }
            reportError(error, stackTrace);
          },
        ),
      );
    }

    controller = StreamController<List<OnlineRoom>>(
      onListen: () {
        // İlk Firestore snapshot'ı gelene kadar ekranı yükleme durumunda
        // bırakma. Oda ve davetler geldikçe aynı stream güncellenir.
        emit();
        subscriptions.add(
          PlayerProfileService(firestore: _firestore)
              .roomCodes(_playerName)
              .listen((codes) {
                for (final code in codes) {
                  watchRoom(code);
                }
                emit();
              }, onError: reportError),
        );
        // Best-effort discovery of old rooms without membership records.
        // Old invite/history events above also discover past matches.
        for (final field in ['hostUid', 'guestUid', 'invitedGuestUid']) {
          subscriptions.add(
            _firestore
                .collection('rooms')
                .where(field, isEqualTo: _playerId)
                .snapshots()
                .listen(
                  (snapshot) {
                    for (final doc in snapshot.docs) {
                      if (OnlineRoomDto.isRoomData(doc.data())) {
                        watchRoom(doc.id);
                      }
                    }
                  },
                  onError: (Object error, StackTrace stackTrace) {
                    if (error is FirebaseException &&
                        error.code == 'permission-denied') {
                      return;
                    }
                    reportError(error, stackTrace);
                  },
                ),
          );
        }
      },
      onCancel: () async {
        cancelled = true;
        await Future.wait(subscriptions.map((sub) => sub.cancel()));
      },
    );
    return controller.stream;
  }

  @override
  Stream<List<OnlineMove>> moves(String code) => _firestore
      .collection('rooms')
      .doc(code)
      .collection('moves')
      .orderBy('sequence')
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => OnlineMoveDto.fromMap(doc.data()))
            .toList(growable: false),
      );

  @override
  Future<void> submitMove(OnlineRoom room, GeneratedMove move) => _submitEvent(
    room,
    OnlineMove.play(sequence: -1, playerUid: _playerId, move: move),
  );

  @override
  Future<void> passTurn(OnlineRoom room) =>
      _submitEvent(room, OnlineMove.pass(sequence: -1, playerUid: _playerId));

  @override
  Future<void> exchangeTiles(OnlineRoom room, List<String> letters) {
    if (letters.isEmpty || letters.length > 7) {
      throw ArgumentError('Değiştirmek için 1-7 taş seç.');
    }
    return _submitEvent(
      room,
      OnlineMove.exchange(sequence: -1, playerUid: _playerId, letters: letters),
    );
  }

  /// Either player may record a single expired turn after reopening a match.
  /// The expected move count makes simultaneous/stale requests harmless.
  @override
  Future<void> expireTurn(OnlineRoom room) =>
      _submitEvent(room, null, timeout: true);

  @override
  Future<void> finishGame(
    OnlineRoom room, {
    required int hostScore,
    required int guestScore,
  }) async {
    final roomRef = _firestore.collection('rooms').doc(room.code);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(roomRef);
      if (!OnlineRoomDto.isRoomData(snapshot.data())) {
        throw StateError('Oda kapatılmış.');
      }
      final data = snapshot.data()!;
      if (data['hostUid'] != _playerId && data['guestUid'] != _playerId) {
        throw StateError('Bu odanın oyuncusu değilsin.');
      }
      if (data['status'] == 'finished') return;
      if (data['status'] != 'playing') throw StateError('Maç henüz başlamadı.');
      if ((data['moveCount'] as int? ?? 0) != room.moveCount) {
        throw StateError('Maç güncellendi. Yeniden dene.');
      }
      final hostName = data['hostName'] as String? ?? 'Oyuncu 1';
      final guestName = data['guestName'] as String? ?? 'Oyuncu 2';
      final historyRefs = [
        for (final username in {hostName, guestName})
          _profileRef(username).collection('moves').doc('history_${room.code}'),
      ];
      final sequence = _clock().millisecondsSinceEpoch;
      final hostUid = data['hostUid'] as String;
      final guestUid = data['guestUid'] as String?;

      // "Maçı Bitir" manuel pes etme olarak çalışır:
      // butona basan oyuncu skor önde olsa bile kaybeder.
      final winnerUid = _playerId == hostUid ? guestUid : hostUid;

      final history = {
        'action': 'history',
        'sequence': sequence,
        'roomCode': room.code,
        'hostName': hostName,
        'guestName': guestName,
        'hostScore': hostScore,
        'guestScore': guestScore,
        'endedBy': _playerId,
        'winnerUid': winnerUid,
        'finishReason': 'forfeit',
        'createdAt': FieldValue.serverTimestamp(),
      };
      transaction.update(roomRef, {
        'status': 'finished',
        'finishedAt': FieldValue.serverTimestamp(),
        'endedBy': _playerId,
        'winnerUid': winnerUid,
        'finishReason': 'forfeit',
        'hostScore': hostScore,
        'guestScore': guestScore,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      for (final historyRef in historyRefs) {
        // Rakibin geçmiş belgesini önce okumak permission-denied üretebilir.
        // Oda üyeliği yazma için yeterli olduğundan deterministic belgeyi
        // doğrudan set ediyoruz.
        transaction.set(historyRef, history);
      }
    });
  }

  Future<void> _submitEvent(
    OnlineRoom room,
    OnlineMove? event, {
    bool timeout = false,
  }) async {
    final roomRef = _firestore.collection('rooms').doc(room.code);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(roomRef);
      if (!OnlineRoomDto.isRoomData(snapshot.data())) {
        throw StateError('Oda kapatılmış.');
      }
      final current = OnlineRoomDto.fromSnapshot(snapshot);
      if (_playerId != current.hostUid && _playerId != current.guestUid) {
        throw StateError('Bu odanın oyuncusu değilsin.');
      }
      if (!current.isReady || current.moveCount != room.moveCount) {
        if (timeout) return;
        throw StateError('Maç güncellendi. Hamleni yeniden kontrol et.');
      }
      if (timeout) {
        if (!current.isExpired(now: _clock())) return;
      } else {
        if (current.turnUid != _playerId) throw StateError('Sıra sende değil.');
        if (current.isExpired(now: _clock())) {
          throw StateError('Hamle süresi doldu. Sıra rakibe geçiyor.');
        }
      }
      final nextUid = current.turnUid == current.hostUid
          ? current.guestUid
          : current.hostUid;
      if (nextUid == null) throw StateError('Rakip henüz katılmadı.');
      final sequence = current.moveCount;
      final submitted = timeout
          ? OnlineMove.pass(sequence: sequence, playerUid: _playerId)
          : event!.copyWithSequence(sequence);
      final eventRef = roomRef
          .collection('moves')
          .doc(sequence.toString().padLeft(4, '0'));
      transaction.set(eventRef, {
        ...OnlineMoveDto.toMap(submitted),
        if (timeout) ...{
          'reason': 'timeout',
          'expiredPlayerUid': current.turnUid,
        },
      });
      transaction.update(roomRef, {
        'turnUid': nextUid,
        'moveCount': sequence + 1,
        'turnStartedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastMoveId': eventRef.id,
      });
    });
  }
}
