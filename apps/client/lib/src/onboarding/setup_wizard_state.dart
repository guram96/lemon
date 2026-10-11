import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rs_api_client/rs_api_client.dart';
import 'package:rs_core/rs_core.dart';

import '../connection/connection_provider.dart';
import '../platform/client_capabilities.dart';
import '../session/session_provider.dart';

/// Steps of the first-run wizard, in order.
enum SetupStep {
  account('Account'),
  data('Data'),
  library('Library'),
  review('Review');

  const SetupStep(this.label);

  final String label;
}

/// A folder picked on the server, with the server's verdict on it.
@immutable
class CheckedPath {
  const CheckedPath({
    required this.path,
    this.result,
    this.checking = false,
    this.error,
  });

  /// The path as picked, replaced by the normalized one once checked.
  final String path;
  final PathCheckResult? result;
  final bool checking;

  /// Why the check itself failed (server unreachable, invalid path, …).
  final String? error;

  bool get ok => !checking && (result?.ok ?? false);

  int get fileCount =>
      result?.detectedSystems.fold<int>(0, (n, s) => n + s.fileCount) ?? 0;
}

/// An error from `POST /setup`, shown on the step that can fix it.
@immutable
class StepError {
  const StepError(this.step, this.message);

  final SetupStep step;
  final String message;
}

/// Everything the wizard collects. Lives in [setupWizardProvider], so Back /
/// Continue (and leaving the page) keep the input.
@immutable
class SetupWizardState {
  const SetupWizardState({
    this.step = SetupStep.account,
    this.username = '',
    this.password = '',
    this.confirm = '',
    this.accountAttempted = false,
    this.homePath,
    this.data,
    this.roots = const [],
    this.finishing = false,
    this.error,
  });

  final SetupStep step;
  final String username;
  final String password;
  final String confirm;

  /// Continue was pressed on the account step: show every validation error.
  final bool accountAttempted;

  /// The server user's home folder, used as the default browse location.
  final String? homePath;
  final CheckedPath? data;
  final List<CheckedPath> roots;

  /// `POST /setup` is running.
  final bool finishing;
  final StepError? error;

  String? get usernameError {
    if (username.trim().isEmpty) {
      return accountAttempted ? 'Choose a username for the admin' : null;
    }
    return null;
  }

  String? get passwordError {
    const min = SetupRequest.minPasswordLength;
    if (password.length >= min) return null;
    if (password.isEmpty && !accountAttempted) return null;
    return 'Use at least $min characters';
  }

  String? get confirmError {
    if (confirm.isEmpty) {
      return accountAttempted && password.isNotEmpty
          ? 'Type the password again'
          : null;
    }
    return confirm == password ? null : "Passwords don't match";
  }

  bool get accountValid =>
      username.trim().isNotEmpty &&
      password.length >= SetupRequest.minPasswordLength &&
      confirm == password;

  bool get dataValid => data?.ok ?? false;

  /// A library folder that is also the data folder.
  bool get rootClashesWithData {
    final d = data?.result?.path ?? data?.path;
    if (d == null) return false;
    return roots.any((r) => _samePath(r.result?.path ?? r.path, d));
  }

  bool get libraryValid =>
      roots.isNotEmpty && roots.every((r) => r.ok) && !rootClashesWithData;

  /// Distinct systems found across all library folders, with file counts.
  Map<String, int> get detectedSystems {
    final counts = <String, int>{};
    for (final root in roots) {
      for (final s
          in root.result?.detectedSystems ?? const <DetectedSystem>[]) {
        counts.update(
          s.systemId,
          (n) => n + s.fileCount,
          ifAbsent: () => s.fileCount,
        );
      }
    }
    return counts;
  }

  bool canLeave(SetupStep s) => switch (s) {
    SetupStep.account => accountValid,
    SetupStep.data => dataValid,
    SetupStep.library => libraryValid,
    SetupStep.review => accountValid && dataValid && libraryValid,
  };

  SetupWizardState copyWith({
    SetupStep? step,
    String? username,
    String? password,
    String? confirm,
    bool? accountAttempted,
    String? homePath,
    Object? data = _unset,
    List<CheckedPath>? roots,
    bool? finishing,
    Object? error = _unset,
  }) => SetupWizardState(
    step: step ?? this.step,
    username: username ?? this.username,
    password: password ?? this.password,
    confirm: confirm ?? this.confirm,
    accountAttempted: accountAttempted ?? this.accountAttempted,
    homePath: homePath ?? this.homePath,
    data: identical(data, _unset) ? this.data : data as CheckedPath?,
    roots: roots ?? this.roots,
    finishing: finishing ?? this.finishing,
    error: identical(error, _unset) ? this.error : error as StepError?,
  );
}

const _unset = Object();

bool _samePath(String a, String b) {
  String norm(String p) {
    var s = p.replaceAll('\\', '/');
    while (s.length > 1 && s.endsWith('/')) {
      s = s.substring(0, s.length - 1);
    }
    return s.toLowerCase();
  }

  return norm(a) == norm(b);
}

/// Appends [name] to a server-side folder path, using the server's
/// separator.
@visibleForTesting
String joinServerPath(String dir, String name) {
  final windows = dir.contains('\\') && !dir.contains('/');
  final sep = windows ? '\\' : '/';
  return dir.endsWith(sep) ? '$dir$name' : '$dir$sep$name';
}

/// Default name of the data folder suggested inside the home folder.
const defaultDataFolderName = 'RetroSteam';

final setupWizardProvider =
    NotifierProvider<SetupWizardNotifier, SetupWizardState>(
      SetupWizardNotifier.new,
    );

class SetupWizardNotifier extends Notifier<SetupWizardState> {
  bool _preparing = false;

  @override
  SetupWizardState build() => const SetupWizardState();

  RsApiClient get _api => ref.read(apiClientProvider);

  // --- Account ---------------------------------------------------------------

  void setUsername(String v) => state = state.copyWith(username: v);
  void setPassword(String v) => state = state.copyWith(password: v);
  void setConfirm(String v) => state = state.copyWith(confirm: v);

  // --- Navigation ------------------------------------------------------------

  /// Moves to the next step when the current one is complete. Returns
  /// whether it moved.
  bool next() {
    final s = state;
    if (s.step == SetupStep.account && !s.accountAttempted) {
      state = s.copyWith(accountAttempted: true);
    }
    if (!state.canLeave(s.step) || s.step == SetupStep.review) return false;
    state = state.copyWith(
      step: SetupStep.values[s.step.index + 1],
      error: null,
    );
    return true;
  }

  /// Goes back one step. Returns `false` on the first step.
  bool back() {
    final s = state;
    if (s.step.index == 0 || s.finishing) return false;
    state = s.copyWith(step: SetupStep.values[s.step.index - 1], error: null);
    return true;
  }

  /// Jumps to [step] (from the review summary).
  void goTo(SetupStep step) {
    if (state.finishing) return;
    state = state.copyWith(step: step, error: null);
  }

  // --- Data folder -----------------------------------------------------------

  /// Suggests `<home>/RetroSteam` as the data folder, so the user can just
  /// press Continue. Safe to call more than once.
  Future<void> prepare() async {
    if (_preparing || state.homePath != null) return;
    _preparing = true;
    try {
      final listing = await _api.browse(null);
      if (!ref.mounted) return;
      final home =
          listing.shortcuts.where((s) => s.name == 'Home').firstOrNull?.path ??
          listing.path;
      state = state.copyWith(homePath: home);
      if (state.data == null) {
        await chooseDataDir(joinServerPath(home, defaultDataFolderName));
      }
    } on Object {
      // No suggestion; the user browses instead.
    } finally {
      _preparing = false;
    }
  }

  Future<void> chooseDataDir(String path) async {
    state = state.copyWith(
      data: CheckedPath(path: path, checking: true),
      error: null,
    );
    final checked = await _check(path, PathKind.dataDir);
    if (!ref.mounted) return;
    if (state.data?.path != path) return; // Picked another folder meanwhile.
    state = state.copyWith(data: checked);
  }

  Future<void> recheckData() async {
    final d = state.data;
    if (d != null) await chooseDataDir(d.path);
  }

  // --- Library folders -------------------------------------------------------

  Future<void> addRoot(String path) async {
    if (state.roots.any((r) => _samePath(r.path, path))) return;
    state = state.copyWith(
      roots: [
        ...state.roots,
        CheckedPath(path: path, checking: true),
      ],
      error: null,
    );
    await _checkRoot(path);
  }

  void removeRoot(String path) {
    state = state.copyWith(
      roots: [
        for (final r in state.roots)
          if (r.path != path) r,
      ],
    );
  }

  Future<void> recheckRoot(String path) async {
    _replaceRoot(path, (r) => CheckedPath(path: r.path, checking: true));
    await _checkRoot(path);
  }

  Future<void> _checkRoot(String path) async {
    final checked = await _check(path, PathKind.libraryRoot);
    if (!ref.mounted) return;
    // Two picks can normalize to the same folder: keep the first.
    final normalized = checked.path;
    if (normalized != path &&
        state.roots.any(
          (r) => r.path != path && _samePath(r.path, normalized),
        )) {
      removeRoot(path);
      return;
    }
    _replaceRoot(path, (_) => checked);
  }

  void _replaceRoot(String path, CheckedPath Function(CheckedPath) update) {
    state = state.copyWith(
      roots: [for (final r in state.roots) r.path == path ? update(r) : r],
    );
  }

  Future<CheckedPath> _check(String path, PathKind kind) async {
    try {
      final result = await _api.checkPath(path, kind);
      return CheckedPath(path: result.path, result: result);
    } on ApiException catch (e) {
      return CheckedPath(path: path, error: _describe(e));
    } on Object {
      return CheckedPath(path: path, error: 'Could not check this folder.');
    }
  }

  // --- Finish ----------------------------------------------------------------

  /// Runs `POST /setup` and logs the admin in. On success the router moves
  /// to the done page by itself. On failure the wizard returns to the step
  /// that can fix the problem and shows the server's message there.
  Future<void> finish() async {
    final s = state;
    if (s.finishing || !s.canLeave(SetupStep.review)) return;
    state = s.copyWith(finishing: true, error: null);
    try {
      final result = await _api.setup(
        SetupRequest(
          adminUsername: s.username.trim(),
          adminPassword: s.password,
          dataDir: s.data!.result?.path ?? s.data!.path,
          libraryRoots: [for (final r in s.roots) r.result?.path ?? r.path],
          deviceName: ref.read(clientCapabilitiesProvider).deviceName,
        ),
      );
      if (!ref.mounted) return;
      // Don't keep the password around once it served its purpose.
      state = state.copyWith(password: '', confirm: '');
      await ref.read(sessionProvider.notifier).adoptAuthResult(result);
      if (!ref.mounted) return;
      state = state.copyWith(finishing: false);
    } on ApiException catch (e) {
      if (!ref.mounted) return;
      if (e.error.code == ApiErrorCodes.alreadyConfigured) {
        state = state.copyWith(finishing: false);
        // The server is configured after all: probing again lands on login.
        await ref.read(connectionProvider.notifier).retry();
        return;
      }
      final step = stepForError(e);
      state = state.copyWith(
        finishing: false,
        step: step,
        error: StepError(step, _describe(e)),
      );
      if (step == SetupStep.data) {
        await recheckData();
      } else if (step == SetupStep.library) {
        for (final r in state.roots) {
          await recheckRoot(r.path);
        }
      }
    } on Object {
      if (!ref.mounted) return;
      state = state.copyWith(
        finishing: false,
        error: const StepError(
          SetupStep.review,
          'Something went wrong. Try again.',
        ),
      );
    }
  }

  /// The step whose input caused a `POST /setup` failure.
  @visibleForTesting
  static SetupStep stepForError(ApiException e) {
    final message = e.error.message.toLowerCase();
    switch (e.error.code) {
      case ApiErrorCodes.pathInvalid:
        return message.startsWith('data folder')
            ? SetupStep.data
            : SetupStep.library;
      case ApiErrorCodes.badRequest:
        if (message.contains('library')) return SetupStep.library;
        if (message.contains('username') || message.contains('password')) {
          return SetupStep.account;
        }
        return SetupStep.review;
      case ApiErrorCodes.conflict:
        // "This data folder already belongs to a Retro Steam server. Enter
        // its admin username and password …"
        return message.contains('admin') ? SetupStep.account : SetupStep.review;
      default:
        return SetupStep.review;
    }
  }

  static String _describe(ApiException e) => e.isUnreachable
      ? 'Lost the connection to the server. Make sure it is still running.'
      : e.error.message;
}
