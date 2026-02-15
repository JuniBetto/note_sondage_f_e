import 'package:note_sondage/core/utils/interface/api_interceptor.dart';
import 'package:note_sondage/domain/entities/all_enum.dart';

class ApiConfig {
  final String baseUrl;
  final Duration timeout;
  final ApiType apiType;
  final Map<String, String> defaultHeaders;
  final List<ApiInterceptor> interceptors;

  ApiConfig(
    this.apiType, {
    required this.baseUrl,
    this.timeout = const Duration(seconds: 30),
    this.defaultHeaders = const {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    },
    this.interceptors = const [],
  });
}
