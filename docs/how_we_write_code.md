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

2. Don't use abbreviations/short verion of words when name variable/class/method/etc.

    ✅ DO

    ```dart
    var cleanArchitecture = 'That is good';
    var windowsComputer = 'It is good for pc games';

    extension SecondItemGetterExtension on List<Int> {}
    ```

    ❌ DON'T

    ```dart
    var clnArch = 'That is good';
    var wndsCmptr = 'It is good for pc games';

    extension SecondItemGetterX on List<Int> {}
    ```
