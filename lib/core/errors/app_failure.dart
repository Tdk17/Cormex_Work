class AppFailure implements Exception {
  final String code;
  final String message;
  final String? requestId;

  const AppFailure(this.code, this.message, [this.requestId]);

  @override
  String toString() => message;
}
