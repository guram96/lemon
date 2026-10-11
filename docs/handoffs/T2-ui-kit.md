# T2 UI kit — handoff for client agents (T6, T7, T8)

Import `package:rs_ui/rs_ui.dart` (never `rs_ui_steam` from features). Tokens: `context.rsTokens`
(`spacing`, `radii`, `motion` incl. `fast/slow/toastHold`, `sizes`, `breakpoints`), `context.rsLayout`,
`context.rsPageGutter` (align page content with shelves/grids). Preview everything:
`cd apps/client && flutter run -d macos -t lib/gallery_main.dart`.

## Page frame
- `RsScaffold({required body, topBar?, hints?, background?, extendBodyBehindTopBar=false})` — installs
  `RsTabHost`, so LB/RB reach `RsTopBar`/`RsTabs` anywhere on the page. Use it for every page.
- `RsTopBar({required items: List<RsNavItem(label, icon?)>, required selectedIndex, required onSelected,
  showClock=true, notificationCount=0, onNotifications?, userName?, avatar?, onAvatar?, trailing})`
- `RsButtonHints({required hints: List<RsButtonHint(button: RsControllerButton, label, onPressed?)>, leading})`
- `RsGlyph`, `RsGlyphStyleScope({style: RsGlyphStyle.xbox|playstation|nintendo|keyboard})`

## Controls
- `RsButton`, `RsToggle` (see source), `RsTextField({controller, label, hint, helperText, errorText, obscure,
  enabled, autofocus, focusNode, onChanged, onSubmitted, keyboardType, textInputAction, autofillHints, maxLength, icon})`
- `RsListRow({required title, subtitle, icon, leading, value, switchValue, chevron, trailing, onPressed, autofocus, focusNode, onFocusChanged})`
- `RsTabs({required tabs: List<RsTab(label, count?, icon?)>, required selectedIndex, required onChanged, showBumperHints=true})`
- `RsButton` has no busy state: pair with `RsSpinner`.

## Game art
- `RsGameCard({required title, required onPressed, systemId, systemName, image, layout=RsArtLayout.cover,
  installed, showSystemBadge, progress, autofocus, focusNode, onFocusChanged})` — fills given width.
  Generated art when `image` is null or fails.
- `RsGameArt({required title, systemId, systemName, image, layout})` — non-interactive; use
  `RsArtLayout.background` for the home background cross-fade (`motion.slow`).
- `RsShelf({required title, required itemCount, required itemBuilder, subtitle, trailing, itemWidth,
  itemAspectRatio=2/3, emptyText, controller})` — remembers last focused item.
- `RsGrid({required itemCount, required itemBuilder, itemAspectRatio=2/3, minItemWidth, padding, controller, empty, header})`
- `RsHero({required title, systemId, systemName, image, logo, subtitle, height, child})`
- Page `ListView` of shelves: give it a large `cacheExtent` so d-pad down always lands on a built shelf.

## Feedback & overlays
- `RsProgressBar({value? (null=indeterminate), label, trailing})`, `RsSpinner({size, label})`
- `RsToast({required Key key, required title, body, icon, image, progress, indeterminate, onPressed, onDismiss})`
- `RsToastStack({required toasts})` — put in `Positioned.fill`/Overlay above the router; positions itself
  bottom-right, animates by key, taps pass through. Auto-dismiss after `motion.toastHold`.
- `RsDialog({title, message, content, actions, icon, maxWidth})`, `showRsDialog<T>({context, builder, dismissible=true})`
  — focus trapped, B closes.
- `RsWizardFrame({required steps, required currentStep, required title, required child, subtitle, icon,
  primaryAction, secondaryAction, extraActions, scrollable=true})` — step changes animate without
  rebuilding the child (form state survives).
