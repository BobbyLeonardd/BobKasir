# BobKasir 🛒

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![SQLite](https://img.shields.io/badge/SQLite-07405E?style=for-the-badge&logo=sqlite&logoColor=white)

BobKasir is a robust, offline-first Point of Sale (POS) application built with Flutter. Designed for speed, reliability, and ease of use, it allows cashiers to process transactions seamlessly even without a stable internet connection.

## ✨ Features

- **Offline-First Architecture**: Built on top of `drift` (SQLite), ensuring the app remains fully functional without an internet connection.
- **Background Synchronization**: Automatically syncs pending transactions to the backend when the network is restored using a custom `SyncService` and `connectivity_plus`.
- **Reactive State Management**: Powered by `flutter_riverpod` for predictable, scalable, and testable state handling.
- **Split Bill & Flexible Payments**: Supports complex payment scenarios including split bills and multiple payment methods (Cash, QRIS, Transfer).
- **Clean Architecture**: Adheres to a strict feature-based directory structure separating data, domain, and presentation layers.

## 🛠️ Tech Stack

- **Framework**: Flutter
- **State Management**: Riverpod (`flutter_riverpod`, `riverpod_annotation`)
- **Local Storage**: Drift (SQLite)
- **Networking**: Dio
- **Routing**: GoRouter
- **Code Generation**: `build_runner`, `drift_dev`, `riverpod_generator`

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (>=3.0.0)
- Dart SDK
- SQLite (for desktop/web platforms if applicable)

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/BobbyLeonardd/BobKasir.git
   cd BobKasir
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run code generation (required for Drift and Riverpod):
   ```bash
   dart run build_runner build -d
   ```

4. Run the app:
   ```bash
   flutter run
   ```

## 📂 Project Structure

```
lib/
├── core/                   # Core functionality (DB, API, Theme, Routing)
│   ├── database/           # Drift tables and AppDatabase
│   ├── models/             # Data models
│   ├── providers/          # Global Riverpod providers
│   ├── repositories/       # Data repositories mapping local DB & API
│   └── services/           # Background sync, API client
├── features/               # Feature modules
│   ├── auth/               # Login, OTP, Onboarding
│   ├── dashboard/          # Analytics and charts
│   ├── kasir/              # Core POS flow (Cart, Checkout, Receipt)
│   ├── produk/             # Product and catalog management
│   ├── riwayat/            # Order history and sync status
│   └── settings/           # App configuration, printers, users
└── widgets/                # Reusable UI components
```

## 🤝 Contributing

Contributions, issues, and feature requests are welcome. Feel free to check the [issues page](../../issues).

## 📄 License

This project is proprietary and confidential. Unauthorized copying of this file, via any medium, is strictly prohibited.
