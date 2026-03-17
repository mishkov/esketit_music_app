class NullableOption<T> {
  final T? value;

  NullableOption.nullable() : value = null;

  NullableOption.value(T this.value);
}