import 'package:dio/dio.dart';

class ApiException implements Exception {
  final int? code;
  final String message;
  final String? requestId;

  const ApiException({required this.message, this.code, this.requestId});

  /// 从任意异常（DioException 或普通 Exception）提取标准 ApiException
  factory ApiException.from(dynamic error) {
    if (error is ApiException) return error;

    if (error is DioException) {
      // 1. 如果拦截器已经把 ApiException 塞进了 error.error，直接取出
      if (error.error is ApiException) {
        return error.error as ApiException;
      }

      // 2. 如果 HTTP 非 2xx 响应体里带有后端的标准 {code, message} 结构
      final resData = error.response?.data;
      if (resData is Map<String, dynamic>) {
        final rawCode = resData['code'];
        final int? parsedCode = rawCode is int ? rawCode : int.tryParse(rawCode?.toString() ?? '');
        final msg = resData['message']?.toString();
        if (msg != null && msg.isNotEmpty) {
          return ApiException(
            code: parsedCode ?? error.response?.statusCode,
            message: msg,
            requestId: resData['requestId']?.toString(),
          );
        }
      }

      // 3. 物理网络与 HTTP 状态码兜底转换
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return const ApiException(code: -1, message: '网络连接超时，请稍后重试');
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          if (statusCode == 401) {
            return const ApiException(code: 401, message: '登录已过期，请重新登录');
          }
          if (statusCode == 403) {
            return const ApiException(code: 403, message: '暂无权限访问');
          }
          return ApiException(code: statusCode, message: '服务器开小差了 ($statusCode)');
        case DioExceptionType.connectionError:
          return const ApiException(code: -1, message: '网络未连接，请检查网络设置');
        case DioExceptionType.cancel:
          return const ApiException(code: -2, message: '请求已取消');
        default:
          return const ApiException(code: -1, message: '网络请求异常，请稍后重试');
      }
    }

    if (error is TypeError || error is FormatException) {
      return const ApiException(code: -98, message: '数据解析异常');
    }

    return ApiException(code: -99, message: error?.toString() ?? '未知错误');
  }

  /// 重写 toString，直接返回可读文案，方便 UI 层直接展示
  @override
  String toString() => message;
}
