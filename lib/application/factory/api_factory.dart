import 'package:note_sondage/core/network/api_config.dart';
import 'package:note_sondage/core/utils/interface/api_interceptor.dart';
import 'package:note_sondage/domain/repositories/interface_api_service.dart';

abstract class ApiFactory {
  IApiService createService(
    ApiConfig config, {
    List<ApiInterceptor>? additionalInterceptors,
  });
}
