# Kelime Firebase backend

This folder contains the server-side part required by the Stitch screens.

- `matchmaking_queue`: pairs players who selected the same turn duration.
- `players`: public profile, preferences and aggregate statistics.
- `leaderboard_weekly` / `leaderboard_all_time`: ranking projections.
- Firebase Authentication: e-mail/password login and password reset.
- Firebase Storage: profile pictures under `avatars/{uid}/profile.jpg`.

Before deploying the production rules, switch the app bootstrap from the
legacy device profile to `AccountService`; the secure rules require an
authenticated Firebase user. Then run `firebase deploy` from `arena-v07`.
