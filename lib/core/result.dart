/// A small Result type so domain use-cases (createReminder, editReminder,
/// deleteReminder, ...) can return either a value or a failure reason
/// without throwing exceptions across module boundaries.
///
/// Reusable beyond this app: this file has zero knowledge of reminders.
/// Copy it into any Flutter/Dart project as-is.
library reusable_reminder_kit.core.result;

/// Base type. Use [Result.ok] / [Result.fail] to construct.
abstract class Result<T> {
  const Result();

  factory Result.ok(T value) = Ok<T>;
  factory Result.fail(String message, {Object? cause}) = Fail<T>;

  bool get isOk => this is Ok<T>;
  bool get isFail => this is Fail<T>;

  /// Returns the value if [Ok], otherwise throws [StateError].
  /// Prefer [when] or [valueOrNull] in real code paths.
  T get value {
    final self = this;
    if (self is Ok<T>) return self.data;
    throw StateError('Tried to read .value on a Fail result: ${(self as Fail<T>).message}');
  }

  T? get valueOrNull => this is Ok<T> ? (this as Ok<T>).data : null;

  /// Pattern-match without needing `is` checks at call sites.
  R when<R>({
    required R Function(T value) ok,
    required R Function(String message, Object? cause) fail,
  }) {
    final self = this;
    if (self is Ok<T>) return ok(self.data);
    final f = self as Fail<T>;
    return fail(f.message, f.cause);
  }
}

class Ok<T> extends Result<T> {
  final T data;
  const Ok(this.data);
}

class Fail<T> extends Result<T> {
  final String message;
  final Object? cause;
  const Fail(this.message, {this.cause});
}
