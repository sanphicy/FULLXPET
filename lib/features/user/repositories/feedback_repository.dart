import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fullxpet/core/network/api_client.dart';
import 'package:fullxpet/core/network/api_endpoints.dart';
import 'package:fullxpet/core/network/api_exception.dart';
import 'package:fullxpet/locator.dart';
import '../models/feedback_dto.dart';

class FeedbackRepository {
  final Dio _dio = locator<ApiClient>().dio;

  /// 上传单张反馈图片
  Future<FeedbackAttachmentDto> uploadImage(XFile image) async {
    final formData = FormData.fromMap({'file': await MultipartFile.fromFile(image.path, filename: image.name)});
    final res = await _dio.post(ApiEndpoints.feedbackImages, data: formData);
    final data = res.data;
    if (data is Map<String, dynamic>) {
      final dto = FeedbackAttachmentDto.fromJson(data);
      if (dto.key.isNotEmpty || dto.url.isNotEmpty) return dto;
    }
    throw const ApiException(message: '图片上传失败，请稍后重试');
  }

  /// 提交意见反馈（priority 固定默认 normal）
  Future<String> createFeedback({
    required FeedbackKind kind,
    required String title,
    required String body,
    String? deviceId,
    String? productId,
    List<FeedbackAttachmentDto> attachments = const [],
  }) async {
    final payload = <String, dynamic>{
      'kind': kind.value,
      'title': title,
      'body': body,
      'priority': 'normal',
      'attachments': [for (final a in attachments) a.toJson()],
      if (deviceId != null && deviceId.isNotEmpty) 'deviceId': deviceId,
      if (productId != null && productId.isNotEmpty) 'productId': productId,
    };

    final res = await _dio.post(ApiEndpoints.feedbacks, data: payload);
    final data = res.data;
    if (data is Map<String, dynamic>) {
      return data['feedbackId']?.toString() ?? '';
    }
    return '';
  }

  /// 分页查询我的反馈列表（page 从 1 开始）
  Future<FeedbackPageResult> getMyFeedbacks({int page = 1, int size = 20}) async {
    final res = await _dio.get(ApiEndpoints.feedbacks, queryParameters: {'page': page, 'size': size});
    final data = res.data;
    if (data is Map<String, dynamic>) {
      return FeedbackPageResult.fromJson(data);
    }
    return const FeedbackPageResult(items: [], page: 1, size: 20, total: 0);
  }

  /// 查询反馈详情
  Future<FeedbackItemDto> getFeedbackDetail(String feedbackId) async {
    final res = await _dio.get(ApiEndpoints.feedbackDetail(feedbackId));
    final data = res.data;
    if (data is Map<String, dynamic>) {
      return FeedbackItemDto.fromJson(data);
    }
    throw const ApiException(message: '未获取到反馈详情');
  }
}
