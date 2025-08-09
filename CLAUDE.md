# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Environment & Development Constraints

This project runs in WSL environment but user develops on Windows. **Do NOT execute Flutter/Dart commands directly** - ask the user to run them manually on their Windows system.

## Project Overview

A Flutter mobile application template with internationalization, theme management, and state management using Riverpod. The project uses code generation heavily and follows Korean development practices (comments and variable names may be in Korean).

## Key Dependencies

- **flutter_riverpod**: State management with code generation
- **riverpod_annotation/riverpod_generator**: Provider code generation
- **hive_flutter**: Local storage for settings
- **flutter_intl**: Internationalization (Korean/English)
- **flutter_svg**: SVG asset handling
- **build_runner**: Code generation runner

## Architecture

### Core Structure
- `lib/core/` - Contains foundational modules:
  - `theme/` - Theme system with light/dark mode support
  - `localization/` - i18n with generated files in `generated/`
  - `util/` - Utilities including debounce service and SVG handling
  - `const/` - Enums for Hive keys and debounce keys

### State Management
Uses Riverpod with code generation. Providers are annotated with `@Riverpod()` and generate `.g.dart` files.

### Theme System
- Abstract `AppTheme` class with concrete `LightTheme` and `DarkTheme`
- Settings persisted via Hive with debounced saves for performance
- Custom extensions on `WidgetRef` for easy theme access

### Debounce Service
Singleton service for delaying expensive operations (like theme/locale saves) with immediate flush capabilities.

## Code Generation Commands

**Important**: Ask user to run these commands on Windows, do not execute directly:

```bash
# Generate all code (providers, Hive adapters, etc.)
flutter packages pub run build_runner build

# Watch for changes and regenerate automatically
flutter packages pub run build_runner watch

# Clean generated files before rebuilding
flutter packages pub run build_runner clean
```

## Internationalization

- ARB files in `lib/core/localization/l10n/`
- Generated files in `lib/core/localization/generated/`
- Supports Korean (`ko`) and English (`en`)
- Use `S.of(context)` or `ref.watch(languageProvider)` for translations

## Common Development Tasks

### Adding New Providers
1. Create provider with `@Riverpod()` annotation
2. Import `riverpod_annotation`
3. Add `part 'filename.g.dart'`
4. Ask user to run code generation

### Theme Development
- Modify `app_color.dart`, `app_font.dart` for styling
- Theme changes auto-save with 5-second debounce
- Access via `ref.theme`, `ref.color`, `ref.font` extensions

### Adding Translations
1. Add keys to ARB files in `l10n/`
2. Ask user to run Flutter intl code generation
3. Use via generated `S` class

## Asset Management

- Custom fonts in `assets/fonts/` (Pretendard, SpaceMono)
- Font weights configured in `pubspec.yaml`
- SVG icons handled through `SvgIcon` widget with color targeting

## Analysis & Linting

- Uses `flutter_lints` with custom rules
- Excludes generated files (`**/*.g.dart`, `**/*.freezed.dart`)
- Custom lint enabled via `riverpod_lint`
- Prefers const constructors and declarations

## Testing

Standard Flutter test structure in `test/` directory. Ask user for specific test commands if needed.