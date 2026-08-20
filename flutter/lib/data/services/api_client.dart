import 'package:dio/dio.dart';

import '../../core/config/api_config.dart';
import '../../core/config/app_config.dart';
import '../interceptors/auth_interceptor.dart';

class ApiClient {
  static ApiClient? current;
  ApiClient({
    required String? Function() tokenReader,
    required Future<void> Function() onUnauthorized,
  }) {
    dio = Dio(AppConfig.apiOptions(ApiConfig.baseUrl));
    dio.interceptors.add(
      AuthInterceptor(tokenReader: tokenReader, onUnauthorized: onUnauthorized),
    );
    current = this;
  }

  late final Dio dio;
}
