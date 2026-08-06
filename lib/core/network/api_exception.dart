import 'package:dio/dio.dart';

class ApiException {
  static String format(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return '网络连接超时，请检查网络';
        case DioExceptionType.badResponse:
          final code = error.response?.statusCode;
          if (code == 401) return '登录凭证已过期';
          if (code == 403) return '权限不足';
          return '服务器异常 ($code)';
        case DioExceptionType.cancel:
          return '请求已取消';
        default:
          return '网络连接异常，请稍后重试';
      }
    }
    return '客户端发生未知错误';
  }
}
