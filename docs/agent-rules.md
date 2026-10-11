# Rules for task agents

Several agents work in the **same working tree at the same time**. These rules
keep them from breaking each other.

1. **Read first:** `CLAUDE.md`, `tasks.md` (your task's section), and
   `docs/api-contract.md` if your task touches the API.
2. **Stay in your lane.** Only edit the paths your task lists under *Owns*.
   If you need a change elsewhere (a new DTO, a new component, a route), don't
   make it: list it under "Requests" in your final report. Tiny exceptions:
   adding a dependency line to your own package's `pubspec.yaml`.
3. **Checks are scoped to your paths.** Other agents may have half-finished
   code. Run:
   - `dart format <your paths>`
   - `dart analyze <your paths>` (or `flutter analyze <your paths>`)
   - `dart test <your test files>` / `flutter test <your test files>`
   Don't run `dart tool/check.dart`; the product owner runs it at integration.
   If a failure comes from a path you don't own, mention it and move on.
4. **Dependencies:** add them to your package's `pubspec.yaml`, then run
   `flutter pub get` at the repo root. If it fails because of someone else's
   change, retry once after a minute, then report it.
5. **Codegen:** only the `rs_core` owner runs `build_runner`. Commit-ready
   generated files stay in the tree.
6. **No git commits, no branch changes, no stashes, no resets.**
7. **Don't edit `tasks.md`, `CLAUDE.md` or `docs/`.** The product owner updates them.
8. Follow `CLAUDE.md`: no hardcoded colors/sizes in UI, everything focusable
   through `RsFocusable`, features import `rs_ui` not `rs_ui_steam`, server
   never imports Flutter, never store absolute ROM paths.
9. **Final report** (your last message), short:
   - What you built (files, public API).
   - How it was verified (commands + results).
   - Deviations from the spec and why.
   - Requests for other tasks / the product owner.
   - Known gaps / TODOs.
