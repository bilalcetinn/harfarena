import {initializeApp} from "firebase-admin/app";
import {getMessaging} from "firebase-admin/messaging";
import {FieldValue, getFirestore, Timestamp} from "firebase-admin/firestore";
import {
  onDocumentCreated,
  onDocumentUpdated,
} from "firebase-functions/v2/firestore";
import {randomBytes} from "node:crypto";

initializeApp();

const db = getFirestore();
const alphabet = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
const notificationChannel = "harf_arena_game_events_v1";
const quietNotificationChannel = "harf_arena_game_events_quiet_v1";

type DocumentData = Record<string, unknown>;
type NotificationType = "turn" | "invite" | "game_opened" | "result";

function stringValue(value: unknown, fallback = ""): string {
  return typeof value === "string" ? value : fallback;
}

function numberValue(value: unknown): number {
  return typeof value === "number" && Number.isFinite(value) ? value : 0;
}

function timestampValue(value: unknown): Timestamp | null {
  return value instanceof Timestamp ? value : null;
}

function notificationSetting(type: NotificationType): string {
  if (type === "turn") return "turnNotifications";
  if (type === "result") return "resultNotifications";
  return "inviteNotifications";
}

async function sendPlayerNotification(
  playerId: string,
  type: NotificationType,
  title: string,
  body: string,
  code: string,
): Promise<void> {
  if (!playerId) return;
  const playerRef = db.collection("players").doc(playerId);
  const [player, devices] = await Promise.all([
    playerRef.get(),
    playerRef.collection("devices").get(),
  ]);
  const settings = (player.data()?.settings ?? {}) as DocumentData;
  if (settings[notificationSetting(type)] === false) return;
  const deviceTokens = devices.docs
    .map((device) => ({id: device.id, token: stringValue(device.data().token)}))
    .filter((device) => device.token.length > 0);
  if (deviceTokens.length === 0) return;

  const vibrate = settings.vibration !== false;
  const response = await getMessaging().sendEachForMulticast({
    tokens: deviceTokens.map((device) => device.token),
    notification: {title, body},
    data: {type, title, body, roomCode: code},
    android: {
      priority: "high",
      notification: {
        channelId: vibrate ? notificationChannel : quietNotificationChannel,
        sound: "turn",
      },
    },
  });

  const staleIds: string[] = [];
  response.responses.forEach((result, index) => {
    const code = result.error?.code;
    if (code === "messaging/registration-token-not-registered" ||
        code === "messaging/invalid-registration-token") {
      staleIds.push(deviceTokens[index].id);
    }
  });
  await Promise.all(
    staleIds.map((id) => playerRef.collection("devices").doc(id).delete()),
  );
}

function displayName(room: DocumentData, playerId: string): string {
  return playerId === stringValue(room.hostUid) ?
    stringValue(room.hostName, "Rakibin") :
    stringValue(room.guestName, "Rakibin");
}

function opponentName(room: DocumentData, playerId: string): string {
  return playerId === stringValue(room.hostUid) ?
    stringValue(room.guestName, "Rakibin") :
    stringValue(room.hostName, "Rakibin");
}

function experienceForMatch(score: number, durationSeconds: number): number {
  const minutes = Math.min(120, Math.max(1, Math.floor(durationSeconds / 60)));
  return Math.max(0, Math.floor(score)) + minutes * 2;
}

async function recordProgression(
  code: string,
  room: DocumentData,
): Promise<void> {
  const hostUid = stringValue(room.hostUid);
  const guestUid = stringValue(room.guestUid);
  if (!hostUid || !guestUid) return;

  const startedAt = timestampValue(room.startedAt) ??
    timestampValue(room.createdAt);
  const finishedAt = timestampValue(room.finishedAt) ??
    timestampValue(room.updatedAt);
  const durationSeconds = startedAt && finishedAt ?
    Math.max(0, finishedAt.seconds - startedAt.seconds) : 0;
  const hostScore = numberValue(room.hostScore);
  const guestScore = numberValue(room.guestScore);
  const winnerUid = stringValue(room.winnerUid) ||
    (hostScore === guestScore ? "" : hostScore > guestScore ? hostUid : guestUid);
  const players = [
    {id: hostUid, score: hostScore},
    {id: guestUid, score: guestScore},
  ];

  await db.runTransaction(async (transaction) => {
    const snapshots = await Promise.all(players.map(async (player) => {
      const playerRef = db.collection("players").doc(player.id);
      const markerRef = playerRef.collection("progression").doc(code);
      const [profile, marker] = await Promise.all([
        transaction.get(playerRef),
        transaction.get(markerRef),
      ]);
      return {player, playerRef, markerRef, profile, marker};
    }));

    for (const item of snapshots) {
      if (item.marker.exists) continue;
      const oldStats = (item.profile.data()?.stats ?? {}) as DocumentData;
      const draw = winnerUid.length === 0;
      const won = !draw && winnerUid === item.player.id;
      const oldStreak = numberValue(oldStats.winStreak);
      const nextStreak = won ? oldStreak + 1 : 0;
      const nextStats = {
        ...oldStats,
        totalGames: numberValue(oldStats.totalGames) + 1,
        wins: numberValue(oldStats.wins) + (won ? 1 : 0),
        losses: numberValue(oldStats.losses) + (!draw && !won ? 1 : 0),
        draws: numberValue(oldStats.draws) + (draw ? 1 : 0),
        totalScore: numberValue(oldStats.totalScore) + item.player.score,
        totalPlaySeconds: numberValue(oldStats.totalPlaySeconds) +
          durationSeconds,
        weeklyScore: numberValue(oldStats.weeklyScore) + item.player.score,
        xp: numberValue(oldStats.xp) +
          experienceForMatch(item.player.score, durationSeconds),
        winStreak: nextStreak,
        bestWinStreak: Math.max(
          numberValue(oldStats.bestWinStreak),
          nextStreak,
        ),
      };
      transaction.set(item.playerRef, {
        stats: nextStats,
        updatedAt: FieldValue.serverTimestamp(),
      }, {merge: true});
      transaction.create(item.markerRef, {
        roomCode: code,
        score: item.player.score,
        durationSeconds,
        xpAwarded: experienceForMatch(item.player.score, durationSeconds),
        createdAt: FieldValue.serverTimestamp(),
      });
    }
  });
}

function roomCode(): string {
  const bytes = randomBytes(8);
  return [...bytes].map((value) => alphabet[value % alphabet.length]).join("");
}

function profileCode(username: string): string {
  let hash = 0x811c9dc5;
  for (const unit of [...username.trim().replace(/\s+/g, "_").toLowerCase()]) {
    hash ^= unit.charCodeAt(0);
    hash = Math.imul(hash, 0x01000193) & 0x7fffffff;
  }
  let value = hash;
  let output = "P";
  for (let index = 0; index < 7; index++) {
    output += alphabet[value % alphabet.length];
    value = Math.floor(value / alphabet.length);
  }
  return output;
}

export const pairMatchmakingPlayers = onDocumentCreated(
  "matchmaking_queue/{playerId}",
  async (event) => {
    const playerId = event.params.playerId as string;
    await db.runTransaction(async (transaction) => {
      const ownRef = db.collection("matchmaking_queue").doc(playerId);
      const own = await transaction.get(ownRef);
      const ownData = own.data();
      if (!ownData || ownData.status !== "searching") return;

      const candidates = await transaction.get(
        db.collection("matchmaking_queue")
          .where("status", "==", "searching")
          .where("turnDurationSeconds", "==", ownData.turnDurationSeconds)
          .orderBy("createdAt")
          .limit(10),
      );
      const opponent = candidates.docs.find((doc) => doc.id !== playerId);
      if (!opponent) return;
      const opponentData = opponent.data();
      if (opponentData.status !== "searching") return;

      const code = roomCode();
      const roomRef = db.collection("rooms").doc(code);
      const now = FieldValue.serverTimestamp();
      transaction.create(roomRef, {
        type: "match",
        hostUid: opponent.id,
        hostName: opponentData.username,
        guestUid: playerId,
        guestName: ownData.username,
        invitedGuestUid: playerId,
        invitedGuestName: ownData.username,
        turnUid: opponent.id,
        status: "playing",
        seed: randomBytes(4).readUInt32BE(0) & 0x7fffffff,
        moveCount: 0,
        turnDurationSeconds: ownData.turnDurationSeconds,
        startedAt: now,
        turnStartedAt: now,
        createdAt: now,
        updatedAt: now,
      });

      for (const player of [
        {id: opponent.id, name: opponentData.username as string},
        {id: playerId, name: ownData.username as string},
      ]) {
        const membership = db.collection("rooms")
          .doc(profileCode(player.name))
          .collection("moves")
          .doc(`membership_${code}`);
        transaction.set(membership, {
          action: "membership",
          sequence: Date.now(),
          roomCode: code,
          createdAt: now,
        });
      }
      transaction.update(ownRef, {
        status: "matched",
        roomCode: code,
        opponentName: opponentData.username,
        updatedAt: now,
      });
      transaction.update(opponent.ref, {
        status: "matched",
        roomCode: code,
        opponentName: ownData.username,
        updatedAt: now,
      });
    });
  },
);

export const notifyCreatedGame = onDocumentCreated(
  "rooms/{roomId}",
  async (event) => {
    const room = event.data?.data() as DocumentData | undefined;
    if (!room || room.type === "profile") return;
    const code = event.params.roomId as string;
    const hostUid = stringValue(room.hostUid);
    const guestUid = stringValue(room.guestUid);
    const invitedGuestUid = stringValue(room.invitedGuestUid);
    const status = stringValue(room.status);

    if (status === "waiting" && invitedGuestUid) {
      await sendPlayerNotification(
        invitedGuestUid,
        "invite",
        "Yeni oyun daveti",
        `${stringValue(room.hostName, "Bir oyuncu")} sana oyun daveti gönderdi.`,
        code,
      );
      return;
    }
    if (status === "playing" && hostUid && guestUid) {
      await Promise.all([
        sendPlayerNotification(
          hostUid,
          "game_opened",
          "Oyun açıldı",
          `${opponentName(room, hostUid)} ile oyun açıldı.`,
          code,
        ),
        sendPlayerNotification(
          guestUid,
          "game_opened",
          "Oyun açıldı",
          `${opponentName(room, guestUid)} ile oyun açıldı.`,
          code,
        ),
      ]);
    }
  },
);

export const processUpdatedGame = onDocumentUpdated(
  "rooms/{roomId}",
  async (event) => {
    const before = event.data?.before.data() as DocumentData | undefined;
    const after = event.data?.after.data() as DocumentData | undefined;
    if (!before || !after || after.type === "profile") return;
    const code = event.params.roomId as string;
    const beforeStatus = stringValue(before.status);
    const afterStatus = stringValue(after.status);
    const hostUid = stringValue(after.hostUid);
    const guestUid = stringValue(after.guestUid);

    if (beforeStatus === "waiting" && afterStatus === "playing" && hostUid) {
      await sendPlayerNotification(
        hostUid,
        "game_opened",
        "Oyun açıldı",
        `${opponentName(after, hostUid)} davetini kabul etti.`,
        code,
      );
    }

    const beforeMoves = numberValue(before.moveCount);
    const afterMoves = numberValue(after.moveCount);
    const nextPlayer = stringValue(after.turnUid);
    if (afterStatus === "playing" && afterMoves > beforeMoves && nextPlayer) {
      const move = await db.collection("rooms")
        .doc(code)
        .collection("moves")
        .doc(String(beforeMoves).padStart(4, "0"))
        .get();
      const moveData = (move.data() ?? {}) as DocumentData;
      const action = stringValue(moveData.action);
      const expiredPlayerId = stringValue(moveData.expiredPlayerUid);
      const actor = displayName(after, expiredPlayerId || stringValue(moveData.playerUid));
      let body = `${actor} hamle yaptı. Sıra sende.`;
      if (action === "play") {
        const word = stringValue(moveData.word).toLocaleUpperCase("tr-TR");
        body = `${actor} hamle yaptı (${word}) ${numberValue(moveData.score)} puan`;
      } else if (stringValue(moveData.reason) === "timeout") {
        body = `${actor} için hamle süresi doldu. Sıra sende.`;
      } else if (action === "pass") {
        body = `${actor} pas geçti. Sıra sende.`;
      } else if (action === "exchange") {
        body = `${actor} taş değiştirdi. Sıra sende.`;
      }
      await sendPlayerNotification(
        nextPlayer,
        "turn",
        "Sıra sende",
        body,
        code,
      );
    }

    if (beforeStatus !== "finished" && afterStatus === "finished") {
      await recordProgression(code, after);
      const hostScore = numberValue(after.hostScore);
      const guestScore = numberValue(after.guestScore);
      const winnerUid = stringValue(after.winnerUid) ||
        (hostScore === guestScore ? "" : hostScore > guestScore ? hostUid : guestUid);
      await Promise.all([
        forResult(hostUid, guestUid, hostScore, guestScore),
        forResult(guestUid, hostUid, guestScore, hostScore),
      ]);

      async function forResult(
        playerId: string,
        opponentId: string,
        score: number,
        opponentScore: number,
      ): Promise<void> {
        if (!playerId || !opponentId) return;
        const result = winnerUid.length === 0 ? "Berabere" :
          winnerUid === playerId ? "Kazandın" : "Kaybettin";
        await sendPlayerNotification(
          playerId,
          "result",
          `Oyun sonucu: ${result}`,
          `${opponentName(after!, playerId)} karşısında ${score} - ${opponentScore}`,
          code,
        );
      }
    }
  },
);
