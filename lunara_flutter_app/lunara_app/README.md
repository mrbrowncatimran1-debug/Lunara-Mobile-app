# Lunara — AI Habit Coach (Flutter)

Flutter app built from the **Lunara — AI Habit Coach** Figma design.

## Get the APK

Every push to `main` builds a release APK on GitHub Actions.

- **Releases** tab → newest "Lunara build N" → download `lunara-N.apk`, or
- **Actions** tab → latest "Build APK" run → `lunara-apk` artifact.

On your phone, open the APK and allow "Install unknown apps" when Android asks.

## What works

- **Today** — greeting, daily progress ring, habit checklist (tap a card to check it off), and an AI nudge with *Try this* + Undo.
- **Progress** — last 7 days (tap a day or bar), check-ins chart, current/best streak, your rhythm (best time of day), "Lunara noticed" insight with *Pair them*.
- **My Habits** — add, edit and remove habits; **Create with AI** makes a 3-habit plan you can tick/untick, *Adjust the plan*, then *Add habits*.
- Data is saved on the phone. Tap the profile photo to change the name.

The AI is **demo logic on the phone** (no internet, no API key). It lives in `lib/coach.dart`, so a real OpenAI/Claude call can replace it later.

## Build on your own computer

```bash
flutter create --platforms=android --org com.lunara --project-name lunara .
flutter pub get
dart run flutter_launcher_icons
flutter build apk --release
```

The APK is at `build/app/outputs/flutter-apk/app-release.apk`.

## Project layout

```
lib/
  main.dart                 app shell, bottom navigation, toast
  theme.dart                colors, radii, shadows, text styles (from Figma Foundations)
  models.dart               habits, check-ins, streaks, saved state
  coach.dart                demo AI: nudges, insights, plans
  widgets.dart              shared components (buttons, cards, ring, nav…)
  screens/today_screen.dart
  screens/progress_screen.dart
  screens/my_habits_screen.dart
  screens/sheets.dart       AI plan sheet, confirmation sheet, habit editor
assets/icons/               21 line icons exported from Figma (SVG)
assets/images/              logo mark, avatar, launcher icon
assets/fonts/               DM Sans + Cormorant Garamond (OFL)
```

## Swap in a sharper logo

`assets/images/logo_mark.png` and the launcher icon were taken from a small render.
Export the **Brand/Logo Mark** component from Figma at 3x PNG, replace
`assets/images/logo_mark.png`, and (optionally) rebuild `app_icon.png` /
`app_icon_foreground.png` from it. Push, and a new APK is built.
