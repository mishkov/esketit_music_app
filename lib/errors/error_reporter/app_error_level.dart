class AppErrorLevel {
  final int value;
  final String description;

  AppErrorLevel(this.value, this.description)
    : assert(
        description.isNotEmpty,
        'Creating error level without description is banned because it makes debugging harder',
      );

  const AppErrorLevel.fatal()
    : value = 100,
      description =
          'Unexpected error, looks like user experience totally broken';

  const AppErrorLevel.regular()
    : value = 0,
      description =
          'Error is mostly expected but need attention if occurs very often';

  const AppErrorLevel.developerMistake()
    : value = 0,
      description = 'If you see this error then developer make some mistake';
}
