# Cousinade 2.0

Application Flutter de reseau social familial prive.

## Stack

- Flutter + Dart null safety
- Riverpod
- go_router
- Firebase Auth / Firestore / Storage / Messaging

## Lancer le projet

1. Installer Flutter stable
2. Ajouter la configuration Firebase du projet:
   - `android/app/google-services.json`
   - `ios/Runner/GoogleService-Info.plist`
3. Activer Email/Password dans Firebase Authentication
4. Deployer les regles/index Firestore:
   - `firebase deploy --only firestore:rules`
   - `firebase deploy --only firestore:indexes`
5. Lancer:
   - `flutter pub get`
   - `flutter run`

## Arborescence

Architecture clean autour de `core/`, `shared/`, `features/`.

## Verification

- `flutter analyze` -> OK
- `flutter test` -> OK
