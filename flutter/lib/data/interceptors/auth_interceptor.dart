import 'package:dio/dio.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor({required this.tokenReader, required this.onUnauthorized});

  final String? Function() tokenReader;
  final Future<void> Function() onUnauthorized;
  bool _handlingUnauthorized = false;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final String? token = tokenReader();
    if (token != null && token.isNotEmpty && !options.path.contains('/auth/')) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401 && !_handlingUnauthorized) {
      _handlingUnauthorized = true;
      onUnauthorized().whenComplete(() => _handlingUnauthorized = false);
    }
    handler.next(err);
  }
}
