import 'package:equatable/equatable.dart';

class HttpResponse extends Equatable {
  final int statusCode;
  final Object? response;

  const HttpResponse({required this.statusCode, required this.response});

  @override
  List<Object?> get props => [statusCode, response];
}
