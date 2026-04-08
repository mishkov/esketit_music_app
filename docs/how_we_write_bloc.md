# Rules

1. When state's `copyWith` method should support nullable fields then use lib/use_case/shared/nullable_option.dart.

    ✅ DO

    ```dart
    class ExampleState {
        final String? message;

        const ExampleState({required this.message});
        
        ExampleState copyWith({
            NullableOption<String>? message,
        }) {
            return ExampleState(
                message: message == null ? this.message : message.value,
            );
        }
    }
    ```

    ❌ DON'T

    ```dart
    class ExampleState {
        final String? message;

        const ExampleState({required this.message});
        
        ExampleState copyWith({
            Object? message = _sentinelValue,
        }) {
            return ExampleState(
                message: message == _sentinelValue ? this.message : message as String?,
            );
        }
    }

    const Object _sentinelValue = Object();
    ```