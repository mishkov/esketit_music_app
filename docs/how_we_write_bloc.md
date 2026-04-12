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

2. Use `BlocBuilder` only around widgets that really depend on that bloc state. Do not wrap large widget subtrees when only a small part needs rebuilding.

    ✅ DO

    ```dart
    return Column(
        children: [
            const Header(),
            BlocBuilder<ExampleBloc, ExampleState>(
                builder: (context, state) {
                    return Text(state.title);
                },
            ),
        ],
    );
    ```

    ❌ DON'T

    ```dart
    return BlocBuilder<ExampleBloc, ExampleState>(
        builder: (context, state) {
            return Column(
                children: [
                    const Header(),
                    Text(state.title),
                ],
            );
        },
    );
    ```
