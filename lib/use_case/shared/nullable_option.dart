/// Wraps a nullable value so `copyWith` can distinguish between:
///
/// - parameter not provided
/// - parameter provided with a non-null value
/// - parameter provided with `null`
///
/// This is useful when a field itself is nullable, because a regular
/// `copyWith({T? value})` cannot tell whether `null` means "keep old value"
/// or "replace with null".
///
/// Example:
///
/// ```dart
/// class ExampleState {
///   final String? message;
///
///   const ExampleState({required this.message});
///
///   ExampleState copyWith({
///     NullableOption<String>? message,
///   }) {
///     return ExampleState(
///       message: message == null ? this.message : message.value,
///     );
///   }
/// }
///
/// final state = ExampleState(message: 'Hello');
///
/// state.copyWith();
/// // message == 'Hello'
///
/// state.copyWith(message: NullableOption.value('World'));
/// // message == 'World'
///
/// state.copyWith(message: NullableOption.nullable());
/// // message == null
/// ```
class NullableOption<T> {
  final T? value;

  NullableOption.nullable() : value = null;

  NullableOption.value(T this.value);
}
