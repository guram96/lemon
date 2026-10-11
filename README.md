# Retro Steam

Self-hosted retro game library: EmulationStation meets Steam Big Picture.
A headless server manages your ROM collection; clients on any device browse it and download games.

M1–M4 are built: first-run setup, artwork and metadata, resumable downloads, and launching a game. Next is M5, multi-device. The board is [tasks.md](tasks.md). Architecture and commands are in [CLAUDE.md](CLAUDE.md).

```sh
flutter pub get
dart tool/check.dart
```

Build the release macOS client and write `dist/RetroSteam-macos.dmg`:

```sh
bash tool/macos_dmg.sh
```
