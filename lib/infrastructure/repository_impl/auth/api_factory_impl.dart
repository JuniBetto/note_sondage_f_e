import 'package:dio/dio.dart';
import 'package:note_sondage/core/network/api_config.dart';
import 'package:note_sondage/application/factory/api_factory.dart';
import 'package:note_sondage/core/utils/interface/api_interceptor.dart';
import 'package:note_sondage/domain/entities/all_enum.dart';
import 'package:note_sondage/infrastructure/repository_impl/auth/express_api_impl.dart';

class ApiFactoryImpl implements ApiFactory {
  @override
  ExpressApiImpl createService(
    ApiConfig config, {
    List<ApiInterceptor>? additionalInterceptors,
  }) {
    final dio = Dio();

    // Configurazione base
    dio.options.baseUrl = config.baseUrl;
    dio.options.connectTimeout = config.timeout;
    dio.options.receiveTimeout = config.timeout;
    dio.options.headers = config.defaultHeaders;
    switch (config.apiType) {
      case ApiType.express:
        // return ExpressApiServiceImpl(config, additionalInterceptors: additionalInterceptors);
        return ExpressApiImpl(dio: dio, config: config);
      default:
        throw UnimplementedError('Base URL ${config.baseUrl} non supportato.');
    }
  }
}
