import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:fullxpet/core/network/api_exception.dart';
import 'package:fullxpet/core/storage/token_manager.dart';
import 'package:fullxpet/core/services/nav_service.dart';
import 'package:fullxpet/routes/app_router.dart';

class ApiClient {
  late final Dio dio;
  bool _isHandling401 = false;

  ApiClient({required String baseUrl}) {
    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
        headers: {'X-Client-App': 'fullxpet'},
      ),
    );
    dio.interceptors.add(InterceptorsWrapper(onRequest: _onRequest, onResponse: _onResponse, onError: _onError));
  }

  // 切换节点数据
  void updateBaseUrl(String newBaseUrl) {
    if (newBaseUrl.isNotEmpty) {
      dio.options.baseUrl = newBaseUrl;
    }
  }

  Future<void> _onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await TokenManager.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    if (kDebugMode) {
      debugPrint('\n================== API 请求 ==================');
      debugPrint('URL    : ${options.uri}');
      debugPrint('METHOD : ${options.method}');
      if (options.queryParameters.isNotEmpty) debugPrint('QUERY  : ${options.queryParameters}');
      if (options.data != null) debugPrint('BODY   : ${options.data}');
      debugPrint('=================================================');
    }
    handler.next(options);
  }

  void _onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('\n================== API 响应 =================');
      debugPrint('URL    : ${response.requestOptions.uri}');
      debugPrint('STATUS : ${response.statusCode}');
      debugPrint('DATA   : ${response.data}');
      debugPrint('=================================================');
    }

    final resData = response.data;
    if (resData is Map<String, dynamic> && resData.containsKey('code')) {
      final rawCode = resData['code'];
      final int? code = rawCode is int ? rawCode : int.tryParse(rawCode?.toString() ?? '');

      if (code == 0 || code == 200) {
        response.data = resData['data'];
        handler.next(response);
        return;
      }

      if (code != null && code.toString().startsWith('401')) {
        _handleUnauthorized();
      }

      final apiError = ApiException(
        code: code,
        message: resData['message']?.toString() ?? '请求失败',
        requestId: resData['requestId']?.toString(),
      );

      handler.reject(
        DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          error: apiError,
          message: apiError.message,
        ),
      );
      return;
    }
    handler.next(response);
  }

  Future<void> _onError(DioException e, ErrorInterceptorHandler handler) async {
    if (kDebugMode) {
      debugPrint('\n================== API ERROR ====================');
      debugPrint('URL    : ${e.requestOptions.uri}');
      debugPrint('STATUS : ${e.response?.statusCode}');
      debugPrint('TYPE   : ${e.type}');
      debugPrint('DATA   : ${e.response?.data}');
      debugPrint('=================================================');
    }
    if (e.response?.statusCode == 401) {
      _handleUnauthorized();
    }
    final apiException = ApiException.from(e);
    handler.next(e.copyWith(error: apiException, message: apiException.message));
  }

  Future<void> _handleUnauthorized() async {
    if (_isHandling401) return;
    _isHandling401 = true;
    try {
      await TokenManager.clearToken();
      NavService.go(AppRoutes.login);
    } finally {
      Future.delayed(const Duration(seconds: 2), () {
        _isHandling401 = false;
      });
    }
  }
}
