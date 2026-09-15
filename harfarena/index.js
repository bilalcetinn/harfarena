const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {initializeApp} = require("firebase-admin/app");
const {getAuth} = require("firebase-admin/auth");
const {getFirestore} = require("firebase-admin/firestore");

initializeApp();

const db = getFirestore();
const auth = getAuth();

function normalizeUsername(value) {
  return String(value ?? "").trim().replace(/\s+/g, "_");
}

function genericLoginError() {
  return new HttpsError(
    "unauthenticated",
    "Kullanıcı adı veya şifre hatalı.",
  );
}

exports.signInWithUsername = onCall(
  {
    region: "europe-west1",
    timeoutSeconds: 15,
    memory: "256MiB",
  },
  async (request) => {
    const username = normalizeUsername(request.data?.username);
    const usernameKey = String(request.data?.usernameKey ?? "").trim();
    const password = String(request.data?.password ?? "");
    const apiKey = String(request.data?.apiKey ?? "").trim();

    if (
      username.length < 3 ||
      username.length > 16 ||
      !/^P[A-Z2-9]{7}$/.test(usernameKey) ||
      password.length < 6 ||
      apiKey.length < 10
    ) {
      throw new HttpsError(
        "invalid-argument",
        "Giriş bilgileri geçersiz.",
      );
    }

    const indexSnapshot = await db
      .collection("usernames")
      .doc(usernameKey)
      .get();

    if (!indexSnapshot.exists) {
      throw genericLoginError();
    }

    const indexData = indexSnapshot.data() ?? {};
    const storedUsername = normalizeUsername(indexData.username);
    const playerId = indexData.playerId;

    if (
      typeof playerId !== "string" ||
      playerId.length === 0 ||
      storedUsername.toLocaleLowerCase("tr-TR") !==
        username.toLocaleLowerCase("tr-TR")
    ) {
      throw genericLoginError();
    }

    let userRecord;

    try {
      userRecord = await auth.getUser(playerId);
    } catch (_) {
      throw genericLoginError();
    }

    if (!userRecord.email) {
      throw genericLoginError();
    }

    const response = await fetch(
      `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${encodeURIComponent(apiKey)}`,
      {
        method: "POST",
        headers: {
          "content-type": "application/json",
        },
        body: JSON.stringify({
          email: userRecord.email,
          password,
          returnSecureToken: true,
        }),
      },
    );

    if (!response.ok) {
      throw genericLoginError();
    }

    const passwordResult = await response.json();

    if (
      typeof passwordResult.localId !== "string" ||
      passwordResult.localId !== playerId
    ) {
      throw genericLoginError();
    }

    const customToken = await auth.createCustomToken(playerId);

    return {
      customToken,
    };
  },
);
