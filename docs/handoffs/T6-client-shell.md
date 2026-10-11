# T6 client shell — handoff for T7 / T8

All under `apps/client/lib/src/`.

## Providers
- `apiClientProvider` → `RsApiClient` (stable per server). `serverInfoProvider` → `ServerInfo?`
  (`name`, `platform`).
- `connectionProvider` → `ServerConnection {status: searching|unreachable|unconfigured|ready, baseUri, info, isLocal}`.
- `sessionProvider` → `User?`; notifier: `login(u, p) → Future<User>` (throws `ApiException`),
  `adoptAuthResult(AuthResult)`, `logout()`, `handleApiError(e)`, `isAdmin`.
- `clientCapabilitiesProvider` → `ClientCapabilities {canInstallGames, canLaunchGames, platform, deviceName}`.
- `scanStatusProvider` → `ScanStatus` (live). `libraryRevisionProvider` → `int` (bumps on library
  changes and reconnects) — **watch it in every library provider**.
- `notificationCenterProvider` — `show(AppNotification)`, `dismiss(id)`. Scan toasts are automatic.

## Routing (`AppRoutes`)
`/` startup, `/connect`, `/welcome`, `/setup`, `/setup/done`, `/login`, `/home`, `/library`,
`AppRoutes.game(id)`. Redirects are automatic:
- After `setup()` + `adoptAuthResult()` the router moves to `/setup/done` by itself — don't navigate.
- After `login()` the router goes `/home` by itself.
- Open a game with `context.push(AppRoutes.game(id))` so B goes back.

## Pages
- Outside the shell (full `RsScaffold` pages): `onboarding/welcome_page.dart` `WelcomePage`,
  `onboarding/setup_wizard_page.dart` `SetupWizardPage`, `onboarding/setup_done_page.dart` `SetupDonePage`,
  `auth/login_page.dart` `LoginPage`.
- Inside the shell (**body only, no RsScaffold** — the shell provides top bar + hints):
  `home/home_page.dart` `HomePage`, `library/library_page.dart` `LibraryPage`,
  `game/game_page.dart` `GameDetailPage({required String gameId})`.
  `/home` and `/game/:id` draw behind the top bar: pad content by `context.rsTokens.sizes.topBar`.
  `/library` starts below the bar.

## Tests
Override `apiClientFactoryProvider` with a fake `RsApiClient`; use `InMemoryCredentialStore`
via `credentialStoreProvider`. See `apps/client/test/` for existing fakes to reuse.
