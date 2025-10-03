<div align="center">
  <img src="assets/icons/logo.png" alt="Bhukk Logo" width="120" />
  
  <h1>Bhukk Restaurant Admin Panel</h1>
  <strong>Order. Manage. Grow.</strong>
  
  <p>A modern Flutter + GetX powered administrative dashboard for multi‑channel restaurant operations.</p>
  
  <p>
    <a href="#features">Features</a> ·
    <a href="#structure">Structure</a> ·
    <a href="#getting-started">Getting Started</a> ·
    <a href="#commands">Commands</a> ·
    <a href="#architecture">Architecture</a> ·
    <a href="#contributing">Contributing</a>
  </p>
</div>

---

## ✨ Features
- Modern splash + branding consistency (central tagline & wordmark)
- Phone & email auth flows (signup/login) with polished UI & glassmorphism
- Dining table management: staged edits (split / merge / rename) with atomic save + undo snapshots
- Delivery dashboard: interactive metrics, driver assignment, history & online filter
- Orders & earnings views with adjustments, revenue lines, filtering
- Feedback module: rich action sheet (reply, call, copy, notes, history) + CSV export (web & native)
- Liquor / menu modular categories (extensible)
- Notifications panel & controller
- Reusable widgets, cards, and theming utilities
- Responsive two‑column adaptive layouts & decorative gradient blobs

## 🧰 Tech Stack
| Layer | Tech |
|-------|------|
| Framework | Flutter (Dart) |
| State / Routing | GetX |
| Build Targets | Android · iOS · Web · (Desktop scaffolds present) |
| Export | Custom CSV utilities (platform aware) |

## <a id="structure"></a>📁 Project Structure
```
bhukk-restaurant-adminpannel/
├── android/                     # Android platform config
├── ios/                         # iOS platform config
├── web/                         # Web index & manifest
├── linux/ macos/ windows/       # Desktop shells
├── assets/
│   ├── icons/                   # Logo & symbolic icons
│   └── images/                  # Illustrations / marketing
├── lib/
│   ├── main.dart                # Entry point
│   ├── bindings/                # GetX bindings per module
│   ├── cards/                   # Feature specific card widgets
│   ├── controller/              # Business logic & state
│   │   ├── auth/ delivery/ dining/ earnings/ feedback/ ...
│   │   └── notification_controller.dart
│   ├── models/                  # Data models (account, chat_message, etc.)
│   ├── routes/                  # Route definitions (AppPages / AppRoutes)
│   ├── screens/                 # UI screens (auth, delivery, dining, orders...)
│   ├── theme/                   # Branding & style constants
│   ├── utils/                   # Helpers & formatters
│   └── widgets/                 # Reusable generic widgets (splash, panels)
├── test/                        # Widget & unit tests
├── pubspec.yaml                 # Dependencies & assets
└── README.md
```

### Key Patterns
- **Staged Mutations**: Dining changes buffered until explicit save
- **Undo History**: Snapshot model for revert operations
- **Platform Abstraction**: Export utilities separate web vs IO handling
- **Central Branding**: Avoids inconsistent tagline duplication

## <a id="getting-started"></a>🚀 Getting Started
### Prerequisites
- Flutter SDK installed (`flutter --version`)
- A connected device / emulator / Chrome

### Clone
```bash
git clone https://github.com/your-username/bhukk-restaurant-adminpannel.git
cd bhukk-restaurant-adminpannel
```

### Install Dependencies
```bash
flutter pub get
```

### Run (Device autodetect)
```bash
flutter run
```

### Target Specific Platforms
```bash
flutter run -d chrome      # Web
flutter run -d android     # Android device / emulator
flutter run -d ios         # iOS (macOS required)
```

## <a id="commands"></a>🛠 Common Commands
| Action | Command |
|--------|---------|
| Analyze code | `flutter analyze` |
| Format code | `dart format .` |
| Run tests | `flutter test` |
| Build Android (release) | `flutter build apk --release` |
| Build Web (release) | `flutter build web --release` |
| Clean build artifacts | `flutter clean` |

## 🧪 Testing
```bash
flutter test
```
Organize tests to mirror the `lib/` structure for clarity.

## <a id="architecture"></a>🏛 Architecture Notes
- **GetX Controllers** manage domain logic & reactive state
- **Bindings** ensure lazy injection at route activation
- **Widgets vs Cards**: cards are composite feature UI segments; widgets are generic building blocks
- **CSV Export** abstracts web anchor vs file system writes

## ⚙️ Configuration & Environment
Currently no secret management layer. For future API keys consider:
```bash
flutter run --dart-define=API_BASE=https://api.example.com
```
Add a `dart-define` mapping & read via `const String.fromEnvironment('API_BASE')`.

## 🧩 Roadmap (Planned / Ideas)
- Role-based access control
- Real-time WebSocket updates (orders & drivers)
- Offline cache / persistence layer
- Dark mode toggle

## 🤝 <a id="contributing"></a>Contributing
1. Fork repository
2. Create feature branch: `git checkout -b feat/your-feature`
3. Implement & keep commits scoped
4. Run analyzer & tests
5. Open PR with description & screenshots (UI)

### Style Guidelines
- Favor small, testable controllers
- Avoid duplicate constants; leverage `theme/` + `branding.dart`
- Keep UI adaptive (LayoutBuilder / MediaQuery)

## 🐞 Troubleshooting
| Issue | Tip |
|-------|-----|
| Assets not showing | Run `flutter clean` then `flutter pub get`; verify path in `pubspec.yaml` |
| Stale build errors | Delete `build/` or run `flutter clean` |
| Web export download fails | Check browser pop-up permissions & CSV util path |
| Route not found | Ensure route registered in `app_pages.dart` |

## 🪪 License
Add your preferred license. Example placeholder:
```
MIT License © 2025 Bhukk
```

## 🙋 Support
Open an issue or discussion for questions, feature proposals, or bugs.

---
Made with ❤️ using Flutter & GetX.