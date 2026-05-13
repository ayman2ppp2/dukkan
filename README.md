# دكان · Dukkan

> **A retail shop management app built with Flutter**

Dukkan (Arabic for *shop*) is a cross-platform Flutter application designed to help small and medium retail shops manage their inventory, sales, receipts, loans, and finances — all from a single, offline-first app.

---

## Table of Contents

- [Features](#features)
- [Screenshots](#screenshots)
- [Getting Started](#getting-started)
  - [Download (Android)](#download-android)
  - [Build from Source](#build-from-source)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Dependencies](#dependencies)
- [Changelog](#changelog)
- [Roadmap](#roadmap)
- [Contributing](#contributing)
- [License](#license)

---

## Features

### 🛒 Inventory Management
- Add products with a unique name as identifier
- Edit product details (price, quantity, etc.)
- Search the inventory quickly
- Support for **weightable products** (sold by weight/unit)
- Barcode and QR code scanning to look up products

### 🧾 Sales & Receipts
- Create sales receipts from inventory items
- **Hot products** — add items not in your inventory directly to a receipt (not counted in stats)
- **Receipt returns** — reverse a completed sale
- Mark receipts as **loaned** to a specific loaner

### 💰 Loans & Credit
- Add and manage **loaners** (customers with a running tab)
- Assign receipts to loaners; their balance updates automatically
- Sales and profit are still counted in stats even for loaned receipts
- View the full payment history for each loaner

### 👥 Owners / Partners
- Add **owners** — people who supply products and split the profit with you
- Track each owner's sales and payments separately in the stats page

### 📊 Statistics & Reporting
- View sales and profit charts: **daily**, **monthly**, and **all-time**
- Dedicated **spendings page** to track outgoing costs
- Smooth, non-blocking chart rendering for large datasets
- PDF report generation and printing

### 📡 Data Sharing
- Share your full data set between devices over a local network
- The sender generates a **QR code**; the receiver scans it to start the transfer (HTTP-based)

---

## Getting Started

### Download (Android)

Pre-built APKs are available on the [Releases page](https://github.com/ayman2ppp2/dukkan/releases).

> ⚠️ Only **ARM** builds (arm64-v8a / armeabi-v7a) are currently available. Other platforms (x86, web, desktop) are planned for future releases.

1. Go to [Releases](https://github.com/ayman2ppp2/dukkan/releases) and download the latest `.apk`.
2. Enable **Install from unknown sources** in your Android settings if needed.
3. Install and launch the app.

### Build from Source

**Prerequisites**

| Tool | Version |
|------|---------|
| Flutter | ≥ 3.0 |
| Dart SDK | `>=3.0.5 <4.0.0` |
| Android SDK | API 21+ (Android 5.0+) |

**Steps**

```bash
# 1. Clone the repository
git clone https://github.com/ayman2ppp2/dukkan.git
cd dukkan

# 2. Install dependencies
flutter pub get

# 3. Generate Isar database code
dart run build_runner build --delete-conflicting-outputs

# 4. Run in debug mode
flutter run

# 5. Build a release APK (arm64)
flutter build apk --release --target-platform android-arm64
```

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| UI Framework | [Flutter](https://flutter.dev) (Material Design) |
| Language | Dart |
| State Management | [Provider](https://pub.dev/packages/provider) |
| Local Database | [Isar Community](https://pub.dev/packages/isar_community) |
| Charts | [Syncfusion Flutter Charts](https://pub.dev/packages/syncfusion_flutter_charts) |
| PDF Generation | [pdf](https://pub.dev/packages/pdf) + [printing](https://pub.dev/packages/printing) |
| Barcode / QR Scanning | [mobile_scanner](https://pub.dev/packages/mobile_scanner) |
| QR Code Generation | [qr_flutter](https://pub.dev/packages/qr_flutter) |
| Networking | [dio](https://pub.dev/packages/dio) + [network_info_plus](https://pub.dev/packages/network_info_plus) |
| Email | [mailer](https://pub.dev/packages/mailer) |
| Scheduled Tasks | [cron](https://pub.dev/packages/cron) |
| Backend (optional) | [Appwrite](https://appwrite.io) |
| Platforms | Android · iOS · Web · Linux · macOS · Windows |

---

## Project Structure

```
dukkan/
├── lib/                  # All Dart source code
│   ├── assets/           # Images and icons
│   └── ...               # Screens, models, providers, services
├── android/              # Android-specific project files
├── ios/                  # iOS-specific project files
├── web/                  # Web platform entry point
├── linux/                # Linux desktop platform
├── macos/                # macOS desktop platform
├── windows/              # Windows desktop platform
├── test/                 # Unit and widget tests
├── pubspec.yaml          # Dependencies and Flutter config
└── .github/workflows/    # CI/CD (automated APK builds)
```

---

## Dependencies

Key packages used by this project (see `pubspec.yaml` for full list and versions):

- `provider` — state management
- `isar_community` + `isar_community_flutter_libs` — high-performance local NoSQL database
- `syncfusion_flutter_charts` — interactive charts and graphs
- `mobile_scanner` — barcode & QR scanning
- `qr_flutter` — QR code display for data sharing
- `pdf` + `printing` — generate and print receipts/reports
- `screenshot` — capture widgets as images
- `share_plus` — share files and content
- `image_picker` — pick product images
- `permission_handler` — runtime permissions
- `dio` — HTTP client for device-to-device data transfer
- `appwrite` — optional cloud backend
- `mailer` — email support
- `cron` — scheduled background jobs
- `intl` — date/number formatting
- `crypto` — hashing utilities
- `uuid` — unique ID generation
- `restart_app` — restart the app after major settings changes

---

## Changelog

### v2.4.7 *(Latest — May 2026)*
- Maintenance release and hotfixes

### v2.3.92
- Significant performance improvements across the app
- New **Spendings** page to track shop expenses
- Loaner payment history now viewable
- Stats page no longer lags with large datasets

### v2.2.8
- **Loans** — add loaners, assign receipts to them, track balances
- **Hot products** — ad-hoc receipt items outside the inventory
- Reworked data sharing: HTTP server/client with QR-code pairing
- Barcode and QR scanning support

### v2.1.1
- Android 13 support
- Receipt returns (sales reversal)
- Performance improvements

### v2.0.1
- Sell **weightable products**
- Inventory search
- **Owners/Partners** management with split-profit tracking
- Additional charts with improved visualisation

### v1.0.3
- Daily sales chart for the current month

### v1.0.2 *(First public release)*
- Product management (add, edit, unique name ID)
- Basic sales flow
- Statistics page: daily, monthly, all-time sales & profit

---

## Roadmap

- [ ] x86 / Web / Desktop builds
- [ ] Multi-language support (Arabic UI polish)
- [ ] Cloud sync via Appwrite
- [ ] iOS App Store release
- [ ] Customer-facing receipt sharing (email/WhatsApp)

---

## Contributing

Contributions, issues, and feature requests are welcome!

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/my-feature`
3. Commit your changes: `git commit -m 'Add my feature'`
4. Push to the branch: `git push origin feature/my-feature`
5. Open a Pull Request

Please make sure your code passes existing tests and lints:

```bash
flutter test
flutter analyze
```

---

## License

This project does not currently include an explicit license. Please contact the author before using it in a commercial product.

---

*"دكان" means "shop" in Arabic.*
