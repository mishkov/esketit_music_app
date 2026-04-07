# Rules

1. Keep widget tree less nested and more simple.

    ✅ DO

    ```dart
    Widget result = child;
    if (enableSomeWrapper) {
        result = AwesomeWrapper(
            child: result,
        );
    }

    return Align(
        child: Padding(
            padding: const EdgeInsets.all(16),
            child: result
        ),
    );
    ```

    ❌ DON'T

    ```dart
    Widget result = child;
    if (enableSomeWrapper) {
        result = AwesomeWrapper(
            child: result,
        );
    }

    return Align(
        child: Padding(
            padding: const EdgeInsets.all(16),
            child: enableSomeWrapper ?
                AwesomeWrapper(
                    child: result,
                )
                :
                child,
        ),
    );
    ```