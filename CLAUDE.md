# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Structure

This is a monorepo with two independent projects:

- **Root** — Flutter mobile app (`lib/`, `pubspec.yaml`): "Kiang Thai Service", an air conditioning service booking and technician management app
- **`pixel-agents/`** — VS Code extension with its own `CLAUDE.md` covering its full architecture

## Flutter App Commands

```sh
flutter pub get          # Install dependencies
flutter run              # Run on connected device/emulator
flutter run -d chrome    # Run on web
flutter analyze          # Lint and static analysis
flutter test             # Run all tests
flutter build apk        # Build Android APK
flutter build ios        # Build iOS
```

## Flutter App Architecture

**Initialization** (`lib/main.dart`): Loads `.env`, initializes Firebase and Supabase, then mounts the app. Supabase URL and anon key come from `.env` (`SUPABASE_URL`, `SUPABASE_ANON_KEY`).

**Auth routing**: `KiangThaiApp` uses `StreamBuilder<AuthState>` on `Supabase.instance.client.auth.onAuthStateChange`. When authenticated, a follow-up `FutureBuilder` reads `profiles.role` and routes to the matching main screen: `CustomerMainScreen`, `TechnicianMainScreen`, or `AdminMainScreen`. Unauthenticated users land on `LoginScreen`.

**User roles**:
- **Customer** — `lib/ui/customer/`: home, AC / electrical / solar / CCTV / water-pump / electronics booking, booking history with cancellation + rating, profile settings with saved address list
- **Technician** — `lib/ui/technician/`: real-time job board (pending bookings) and assigned jobs, accept/reject/complete flows
- **Admin** — `lib/ui/admin/`: overview, bookings list, user management

**Chat** — `lib/ui/chat/chat_screen.dart`: per-booking messaging between customer and assigned technician (messages table with RLS restricting reads to booking participants + admins).

**Data layer** (`lib/data/`):
- `models/booking.dart` — consumed by `my_bookings_screen.dart`
- `models/message.dart` — consumed by `chat_screen.dart`
- `models/profile.dart` — consumed by `profile_settings_screen.dart` and `admin_users_screen.dart`
- `repositories/auth_repository.dart` — Supabase auth wrapper (sign in, sign up, sign out, profile upsert, role fetch)
- Real-time data uses Supabase `stream()` queries directly in widgets via `StreamBuilder`

**Notifications**: `lib/services/notification_service.dart` initializes Firebase Messaging + `flutter_local_notifications`. Called once from `main.dart` at startup.

**State management**: Primarily `StatefulWidget` with Supabase streams. `lib/providers/` is empty — no Provider/Riverpod in use.

**Folder conventions**:
- `lib/ui/auth/` — authentication screens (login + signup tabs)
- `lib/ui/customer/`, `lib/ui/technician/`, `lib/ui/admin/` — role-specific screens
- `lib/ui/chat/` — chat screen
- `lib/ui/shared/` (empty) and `lib/ui/widgets/` — reusable components (e.g. `shared_booking_fields.dart`)
- `lib/core/theme.dart` — app theme + color tokens
- `lib/services/` — platform services (notifications)
- `lib/data/models/`, `lib/data/repositories/` — models and repositories

**Supabase schema**: See `supabase_setup.sql` at the repo root for the full table/RLS/storage setup (profiles, bookings, messages, `booking-images` bucket).

## Pixel Agents Extension

See `pixel-agents/CLAUDE.md` for the full architecture reference. Quick-start:

```sh
cd pixel-agents
npm install && cd webview-ui && npm install && cd ..
npm run build    # type-check + lint + esbuild + vite
npm run watch    # development watch mode; press F5 in VS Code to launch Extension Dev Host
```
