/// Failed-login bookkeeping for one key (a username or a client address).
class LoginAttemptState {
  const LoginAttemptState({
    required this.failures,
    required this.firstFailureAt,
    this.lockedUntil,
  });

  final int failures;
  final DateTime firstFailureAt;
  final DateTime? lockedUntil;
}

/// Where [LoginRateLimiter] keeps its state. The database implementation
/// (`LoginAttemptRepo`) survives restarts, so restarting the server doesn't
/// reset a lockout.
abstract interface class LoginAttemptStore {
  LoginAttemptState? get(String key);
  void put(String key, LoginAttemptState state);
  void delete(String key);
}

class InMemoryLoginAttemptStore implements LoginAttemptStore {
  final _states = <String, LoginAttemptState>{};

  @override
  LoginAttemptState? get(String key) => _states[key];

  @override
  void put(String key, LoginAttemptState state) => _states[key] = state;

  @override
  void delete(String key) => _states.remove(key);
}

/// Outcome of [LoginRateLimiter.check].
class LoginGate {
  const LoginGate.allowed() : allowed = true, retryAfter = null;
  const LoginGate.blocked(Duration this.retryAfter) : allowed = false;

  final bool allowed;

  /// How long until the next attempt is accepted (for `Retry-After`).
  final Duration? retryAfter;
}

/// Limits password guessing.
///
/// Failures are counted per username and per client address within
/// [window]. Reaching the limit locks that key for [lockout]; each lockout
/// doubles the duration up to [maxLockout]. A successful login clears the
/// username's counter.
///
/// Usage: `check` → verify password → `recordFailure` or `recordSuccess`.
/// Call `check` *before* verifying, so a locked account can't be probed.
class LoginRateLimiter {
  LoginRateLimiter({
    LoginAttemptStore? store,
    this.maxFailuresPerUser = 5,
    this.maxFailuresPerAddress = 20,
    this.window = const Duration(minutes: 15),
    this.lockout = const Duration(minutes: 5),
    this.maxLockout = const Duration(hours: 1),
    DateTime Function()? clock,
  }) : store = store ?? InMemoryLoginAttemptStore(),
       _clock = clock ?? DateTime.now;

  final LoginAttemptStore store;
  final int maxFailuresPerUser;
  final int maxFailuresPerAddress;
  final Duration window;
  final Duration lockout;
  final Duration maxLockout;
  final DateTime Function() _clock;

  static String userKey(String username) =>
      'user:${username.trim().toLowerCase()}';
  static String addressKey(String address) => 'addr:$address';

  /// Whether a login for [username] from [address] may be attempted now.
  LoginGate check(String username, {String? address}) {
    final now = _clock();
    Duration? wait;
    for (final key in _keys(username, address)) {
      final until = store.get(key)?.lockedUntil;
      if (until != null && until.isAfter(now)) {
        final d = until.difference(now);
        if (wait == null || d > wait) wait = d;
      }
    }
    return wait == null ? const LoginGate.allowed() : LoginGate.blocked(wait);
  }

  /// Records a failed attempt (wrong password *or* unknown username).
  void recordFailure(String username, {String? address}) {
    _fail(userKey(username), maxFailuresPerUser);
    if (address != null) _fail(addressKey(address), maxFailuresPerAddress);
  }

  /// Clears the username's failures after a successful login.
  void recordSuccess(String username, {String? address}) {
    store.delete(userKey(username));
  }

  void _fail(String key, int limit) {
    final now = _clock();
    final prev = store.get(key);
    final expired =
        prev == null ||
        (prev.lockedUntil == null &&
            now.difference(prev.firstFailureAt) > window) ||
        (prev.lockedUntil != null &&
            now.difference(prev.lockedUntil!) > window);
    final failures = expired ? 1 : prev.failures + 1;
    final first = expired ? now : prev.firstFailureAt;
    DateTime? lockedUntil = expired ? null : prev.lockedUntil;
    if (failures >= limit) {
      // Lockouts escalate: 1st at the limit, then every further limit.
      final level = (failures ~/ limit) - 1;
      var duration = lockout * (1 << level.clamp(0, 20));
      if (duration > maxLockout) duration = maxLockout;
      if (failures % limit == 0) lockedUntil = now.add(duration);
    }
    store.put(
      key,
      LoginAttemptState(
        failures: failures,
        firstFailureAt: first,
        lockedUntil: lockedUntil,
      ),
    );
  }

  Iterable<String> _keys(String username, String? address) => [
    userKey(username),
    if (address != null) addressKey(address),
  ];
}
