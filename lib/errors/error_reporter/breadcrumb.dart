import 'package:equatable/equatable.dart';

import 'category.dart';

class Breadcrumb extends Equatable {
  final String message;
  final String? context;
  final Category category;
  final Map<String, Object?> data;
  final bool isStepToReproduce;

  /// If [isStepToReproduce] is null then it will be [true] if [category] is
  /// [Category.uiClick] or [Category.uiInput] and false otherwise.
  Breadcrumb({
    required this.message,
    this.context,
    this.category = Category.generic,
    this.data = const {},
    bool? isStepToReproduce,
  }) : isStepToReproduce =
           isStepToReproduce ??
           _calculateIsStepReproduceBasedOnCategory(category);

  static bool _calculateIsStepReproduceBasedOnCategory(Category category) {
    return [Category.uiClick, Category.uiInput].contains(category);
  }

  @override
  List<Object?> get props => [
    message,
    context,
    category,
    data,
    isStepToReproduce,
  ];
}
