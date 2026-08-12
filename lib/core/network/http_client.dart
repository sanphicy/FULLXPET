import 'package:dio/dio.dart';
import 'package:fullxpet/core/result/result_model.dart';
import 'package:fullxpet/core/network/auth_interceptor.dart';
import 'package:fullxpet/core/network/api_exception.dart';
import 'package:fullxpet/core/navigation/nav_service.dart';
import 'package:fullxpet/routes/app_router.dart';
import 'package:fullxpet/core/utils/token_manager.dart';

class HttpClient {
  static final HttpClient _instance = HttpClient._internal();
  factory HttpClient() => _instance;
  late final Dio dio;

  HttpClient._internal();

  void init({required String baseUrl}) {
    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {"X-Client-App": "fullxpet"},
      ),
    );
    dio.interceptors.add(AuthInterceptor(dio));
  }

  Future<ResultEntity<T>> request<T>(
    String path, {
    required String method,
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    T Function(dynamic json)? fromJson,
  }) async {
    try {
      final options = Options(method: method, headers: headers);

      print('\n================== API REQUEST ==================');
      print('URL    : ${dio.options.baseUrl}$path');
      print('METHOD : $method');
      if (queryParameters != null) print('QUERY  : $queryParameters');
      if (data != null) print('BODY   : $data');
      print('=================================================\n');

      final response = await dio.request(path, data: data, queryParameters: queryParameters, options: options);
      final resData = response.data;

      // 打印成功的响应数据
      print('\n================== API RESPONSE =================');
      print('URL    : ${dio.options.baseUrl}$path');
      print('STATUS : ${response.statusCode}');
      print('DATA   : $resData');
      print('=================================================\n');

      if (resData is Map<String, dynamic>) {
        final int? code = resData['code'];
        if (code == 200 || code == 0) {
          final rawData = resData['data'];
          final T? finalData = (fromJson != null && rawData != null) ? fromJson(rawData) : rawData as T?;
          return ResultEntity.success(finalData, msg: resData['message'] ?? '请求成功');
        }
        if (code == 401 || (code != null && code.toString().startsWith('401'))) {
          _handleUnauthorized();
          return ResultEntity.error(resData['message'] ?? '登录已失效', code: code);
        }
        return ResultEntity.error(resData['message'] ?? '请求失败', code: code);
      }
      return ResultEntity.error('未知数据格式');
    } catch (e) {
      if (e is TypeError || e is FormatException) {
        return ResultEntity.error('数据解析异常');
      }

      if (e is DioException) {
        // 打印异常的响应数据（HTTP 错误状态码，比如 400, 401, 500 等）
        print('\n================== API ERROR ====================');
        print('URL    : ${dio.options.baseUrl}$path');
        print('STATUS : ${e.response?.statusCode}');
        print('ERROR  : ${e.type}');
        print('DATA   : ${e.response?.data}');
        print('=================================================\n');

        if (e.type == DioExceptionType.badResponse) {
          final resData = e.response?.data;
          if (resData is Map<String, dynamic>) {
            return ResultEntity.error(
              resData['message'] ?? ApiException.format(e),
              code: resData['code'],
              requestId: resData['requestId'],
            );
          }
        }
      }
      return ResultEntity.error(ApiException.format(e));
    }
  }

  /// 处理登录失效逻辑
  void _handleUnauthorized() async {
    await TokenManager.clearToken();
    // 使用 NavService 全局导航回登录页
    NavService.go(AppRoutes.login);
  }

  Future<ResultEntity<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? headers,
    T Function(dynamic)? fromJson,
  }) => request<T>(path, method: 'PATCH', data: data, headers: headers, fromJson: fromJson);
  Future<ResultEntity<T>> get<T>(String path, {Map<String, dynamic>? query, T Function(dynamic)? fromJson}) =>
      request<T>(path, method: 'GET', queryParameters: query, fromJson: fromJson);

  Future<ResultEntity<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? headers,
    T Function(dynamic)? fromJson,
  }) => request<T>(path, method: 'POST', data: data, headers: headers, fromJson: fromJson);

  Future<ResultEntity<T>> put<T>(String path, {dynamic data, T Function(dynamic)? fromJson}) =>
      request<T>(path, method: 'PUT', data: data, fromJson: fromJson);

  Future<ResultEntity<T>> delete<T>(String path, {dynamic data, T Function(dynamic)? fromJson}) =>
      request<T>(path, method: 'DELETE', data: data, fromJson: fromJson);
}
