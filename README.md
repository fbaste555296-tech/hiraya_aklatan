# Hiraya Aklatan: Digital Library

A production-quality digital library and reading app for books, novels, and comics. Readers browse books, read free released chapters, unlock early-access chapters per chapter, or subscribe to VIP. Admins manage books, chapters, prices, release dates, and verify payments.

## Tech Stack

- **Flutter** (stable) with Dart null safety, Material 3
- **flutter_riverpod** for state management
- **go_router** for navigation with auth and role-based redirects
- **Firebase**: firebase_core, firebase_auth, cloud_firestore
- **Cloudinary** (unsigned uploads only) for image storage
- **image_picker**, **cached_network_image**, **google_fonts**, **intl**, **flutter_dotenv**

## Project Structure

```
lib/
  main.dart, app.dart
  core/
    config/          # env, app constants, Cloudinary config
    theme/           # app_colors, app_theme, app_text_styles, spacing
    router/          # app_router, route names, guards, main shell
    utils/           # validators, formatters, extensions, chapter_access
    widgets/         # reusable widgets (AppButton, AppTextField, BookCard, etc.)
  data/
    models/          # UserModel, BookModel, ChapterModel, PaymentModel, etc.
    repositories/    # AuthRepository, BookRepository, ChapterRepository, etc.
    services/        # FirestoreService, CloudinaryService
    providers/       # shared service providers
  features/
    auth/            # login, register, forgot password
    library/         # book browsing, My Library
    book_details/    # book detail screen with chapter list
    reader/          # reading experience (text + comic)
    payments/        # payment flow, receipt upload, payment history
    vip/             # VIP subscription plans
    profile/         # user profile with logout
    admin/           # admin dashboard, book/chapter management, settings, payment review
    splash/          # splash screen
```

## Design System

| Role | Color | Hex | Used for |
|------|-------|-----|----------|
| Primary | Deep crimson red | `#B3261E` | Buttons, app bar, active tabs |
| Accent | Warm gold | `#F2B233` | VIP badges, highlights |
| Neutral | Warm cream | `#FFF8EC` | Backgrounds, cards |

Text uses near-black `#2B2118`. Status colors (green/orange/red) are reserved for payment status and error/success messages.

Typography: **Poppins** (sans-serif) for UI, **Merriweather** (serif) for reading content.

## Features

### Reader Features
- Browse books with search, genre filter, grid/list toggle
- Book details with chapter list and lock/early-access tags
- Text reader with adjustable font size (14–28pt)
- Comic reader with InteractiveViewer zoom and page swiping
- Reading progress saving (resume where you left off)
- Chapter unlock logic: free, VIP, purchased, or locked

### Payment Features
- Manual e-wallet payments (GCash, Maya)
- Receipt upload to Cloudinary with progress
- Generated reference codes (HA-YYYYMMDD-XXXX)
- Payment history with status chips
- Duplicate reference number blocking

### VIP Features
- Monthly (30 days) and yearly (365 days) plans
- VIP badge on profile
- Access to all early-access chapters
- Expiry tracking and extension

### Admin Features
- Dashboard with statistics (books, users, pending payments, VIP users)
- Book management (CRUD) with cover upload
- Chapter management (CRUD) with text content or comic page upload
- Payment review with batched approve/reject
- Settings management (payment methods, VIP prices)
- User list with role and VIP status

## Setup

### 1. Firebase

1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com).
2. Enable **Email/Password** Authentication.
3. Create a **Cloud Firestore** database (production or test mode).
4. Run `flutterfire configure` to generate `lib/firebase_options.dart`.
5. Deploy the security rules: `firebase deploy --only firestore:rules`
6. Deploy the indexes: `firebase deploy --only firestore:indexes`

### 2. Cloudinary

1. Create a Cloudinary account at [cloudinary.com](https://cloudinary.com).
2. Go to **Settings > Upload** and create an **unsigned upload preset**.
3. Copy `.env.example` to `.env` and fill in your cloud name and upload preset:

```env
CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_UPLOAD_PRESET=your_unsigned_upload_preset
```

**Never put your Cloudinary API secret in the app.** The app uses unsigned uploads only.

### 3. First Admin User

1. Register a new account through the app (it will have the `reader` role).
2. Go to Firebase Console > Firestore > `users` collection.
3. Find your user document and change `role` from `"reader"` to `"admin"`.
4. Restart the app — you will now see the Admin tab in the bottom navigation.

### 4. Run the App

```bash
flutter pub get
flutter run
```

## Firestore Collections

| Collection | Purpose |
|------------|---------|
| `users/{uid}` | User profile, role, VIP expiry |
| `books/{bookId}` | Book metadata (title, author, cover, genres, status) |
| `books/{bookId}/chapters/{chapterId}` | Chapter metadata (number, title, releaseDate, isEarlyAccess, price, type) |
| `chapterContents/{chapterId}` | Locked content (textContent or pageUrls) |
| `unlockedChapters/{userId}_{chapterId}` | Chapter unlock records |
| `payments/{paymentId}` | Payment requests with status |
| `libraries/{userId}/books/{bookId}` | Reading progress (lastChapterId, updatedAt) |
| `settings/app` | App settings (GCash/Maya numbers, QR URL, VIP prices) |

## Security Rules

The app uses Firestore security rules to enforce:
- Readers can read books and chapter metadata
- Chapter content is only readable if: free, purchased, VIP active, or admin
- Users can create payments (status must be "pending") but cannot change role, VIP expiry, or payment status
- Only admins can write books, chapters, settings, and approve/reject payments
- Unlocked chapter documents use `{userId}_{chapterId}` ID format for efficient rule matching

## Testing

```bash
flutter test
```

65 unit tests covering:
- Input validation (email, password, name, price, reference number, etc.)
- Chapter model logic (isFree, isLocked, isReleased, copyWith)
- Chapter access logic (free, VIP, purchased, locked, priority order)
- Payment approval logic (VIP expiry calculation, document ID format, constants)

## Architecture

- **Feature-first, layered architecture**: Widget → Provider → Repository → Service
- **Immutable models** with `fromMap`/`toMap`/`copyWith`
- **AsyncValue** for loading/error/data states
- **No hardcoded colors, strings, or collection names** — all constants in `app_constants.dart`
- **Files under 300 lines** — large widgets extracted into separate files
- **Const constructors** throughout for performance

## License

Private project. All rights reserved.
