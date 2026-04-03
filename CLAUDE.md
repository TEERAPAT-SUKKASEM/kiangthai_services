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

**Auth routing**: `KiangThaiApp` uses `StreamBuilder<AuthState>` on `Supabase.instance.client.auth.onAuthStateChange` to route between `LoginScreen` (unauthenticated) and role-specific main screens (authenticated).

**User roles**:
- **Customer** — `lib/ui/customer/`: home, booking (air conditioning services), booking history with cancellation, profile settings with address management
- **Technician** — `lib/ui/technician/`: job list with real-time Supabase stream updates, job acceptance and completion flows

**Data layer** (`lib/data/`):
- `repositories/auth_repository.dart` — Supabase auth wrapper (sign in, sign up, sign out)
- Real-time data uses Supabase `stream()` queries directly in widgets via `StreamBuilder`

**State management**: Primarily `StatefulWidget`; `provider` package is a dependency but not yet heavily used. `lib/providers/` is currently empty.

**Folder conventions**:
- `lib/ui/auth/` — authentication screens
- `lib/ui/customer/` — customer-facing screens
- `lib/ui/technician/` — technician-facing screens
- `lib/ui/shared/` and `lib/ui/widgets/` — reusable components
- `lib/core/` — utilities (currently empty)
- `lib/data/models/` — data models (currently empty)

## Pixel Agents Extension

See `pixel-agents/CLAUDE.md` for the full architecture reference. Quick-start:

```sh
cd pixel-agents
npm install && cd webview-ui && npm install && cd ..
npm run build    # type-check + lint + esbuild + vite
npm run watch    # development watch mode; press F5 in VS Code to launch Extension Dev Host
```
