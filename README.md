# 🎮 HarfArena

HarfArena is an actively developed Turkish word game built with Flutter.

The project combines a rule-based word engine, online multiplayer features, player profiles, matchmaking, game analysis, and Firebase-powered backend services in a modern mobile application.

> 🚧 HarfArena is currently under active development.

---

## ✨ Features

### 🎯 Word Game Engine

- 15×15 board system
- 7-tile rack
- Turkish character support
- Word validation
- Premium cells
- Joker tile support
- Score calculation
- Cross-word validation
- Trie-based dictionary search
- Top move generation
- Position analysis
- Move quality evaluation

### 🌐 Online Multiplayer

- Online game rooms
- Matchmaking
- Game invitations
- Turn-based gameplay
- Real-time game state handling
- Match result screens

### 👤 Player System

- User authentication
- Email verification
- Player profiles
- Profile editing
- Player statistics
- Match history
- Leaderboard
- Local player settings

### 🔔 Application Features

- In-app notifications
- Game invitations
- Sound effects
- Animated UI elements
- Custom mobile interface
- Game analysis screen

---

## 🧠 Analysis Engine

HarfArena includes an independent rule-based engine capable of generating and evaluating legal moves on a 15×15 Turkish word board.

The engine supports:

- Trie-based move generation
- Perpendicular cross-check validation
- Word and letter multipliers
- Joker tiles
- Multi-word scoring
- Best-move search
- Played-move comparison
- Score-loss calculation
- Move efficiency analysis

Example:

```dart
final dictionary =
    await DictionaryLoader.loadTrie('assets/words.txt');

final engine = TrieMoveGenerator(
  dictionary: dictionary,
);

final board = KelimelikBoard.classic();

final moves = engine.generate(
  board: board,
  rack: const ['K', 'A', 'L', 'E', 'R', 'T', 'A'],
  limit: 10,
);
```

---

## 🔍 Position Analysis

The analysis engine can compare a played move against the best move available in the current position.

```dart
final analyzer = PositionAnalyzer(
  moveGenerator: engine,
);

final result = analyzer.analyze(
  board: board,
  rack: const ['K', 'A', 'L', 'E', 'R', 'T', 'A'],
  playedMove: playedMove,
);

print(result.bestMove);
print(result.scoreLoss);
print(result.efficiency);
print(result.quality);
```

The current evaluation system primarily focuses on immediate score efficiency.

Future versions may include additional strategic factors such as rack value, board control and deeper position evaluation.

---

## 🏗️ Architecture

The mobile application follows a layered structure separating UI, domain logic and data access.

```text
mobile_app/
├── lib/
│   ├── core/
│   ├── data/
│   ├── domain/
│   ├── di/
│   └── ui/
├── assets/
├── test/
└── android/
```

### Main Layers

**UI**
- Views
- Reusable widgets
- Game interface
- Profile screens

**Domain**
- Models
- Repository abstractions
- Game rules
- Validation services

**Data**
- DTOs
- Firebase services
- API implementations
- Repository implementations

---

## 🛠️ Tech Stack

### Mobile

- Flutter
- Dart

### State & Architecture

- Riverpod
- Layered Architecture
- Repository Pattern

### Backend

- Firebase
- Firebase Authentication
- Firestore
- Cloud Functions
- Firebase Storage

### Backend Functions

- TypeScript
- Node.js

### Development

- Git
- GitHub
- VS Code
- Android

---

## 🗂️ Project Structure

```text
harfarena/
│
├── mobile_app/          # Flutter mobile application
├── backend/             # Backend / Cloud Functions
├── firebase/            # Firestore and Storage rules
├── lib/                 # Core Turkish word engine
├── test/                # Engine tests
├── tool/                # Dictionary tooling
├── windows_app/         # Development/testing utility
├── assets/              # Dictionary assets
└── example/             # Engine usage examples
```

---

## 🧪 Testing

The project includes unit and widget tests covering multiple parts of the application.

Tested areas include:

- Dictionary loading
- Word generation
- Move validation
- Score calculation
- Board rules
- Position analysis
- Player progression
- Match history
- Online game services
- Matchmaking
- UI interactions
- Application bootstrap

Run engine tests with:

```bash
dart test
```

For the Flutter application:

```bash
cd mobile_app
flutter test
```

---

## 🚀 Running the Mobile App

### Requirements

- Flutter SDK
- Dart SDK
- Android SDK

Clone the repository:

```bash
git clone https://github.com/bilalcetinn/harfarena.git
cd harfarena/mobile_app
```

Install dependencies:

```bash
flutter pub get
```

Run the application:

```bash
flutter run
```

---

## 📚 Dictionary

The word engine uses a normalized Turkish word list stored independently from the game logic.

Dictionary processing is handled through:

```bash
dart run tool/build_dictionary.dart source_words.txt assets/words.txt
```

The tool:

- Normalizes Turkish characters
- Removes invalid entries
- Removes duplicates
- Filters unsupported word lengths

Dictionary source and licensing information are documented in:

```text
THIRD_PARTY_NOTICES.md
```

---

## 🗺️ Roadmap

Planned improvements include:

- Improved multiplayer experience
- Better matchmaking
- More detailed player statistics
- Expanded game analysis
- Improved position evaluation
- Performance optimizations
- Additional game modes
- UI/UX improvements
- Production release preparation

---

## ⚠️ Disclaimer

HarfArena is an independent software project.

It does not use private APIs, proprietary client code or private word databases belonging to third-party word games.

The game rules and analysis engine are independently implemented.

---

## 👨‍💻 Developer

Developed by **Bilal Cetin**

Computer Engineering Student  
Flutter & Software Developer

GitHub: [@bilalcetinn](https://github.com/bilalcetinn)

---

⭐ If you find the project interesting, feel free to follow its development.