import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fullxpet/core/network/api_client.dart';
import 'package:fullxpet/core/network/api_endpoints.dart';
import 'package:fullxpet/locator.dart';

class UserRepository {
  final Dio _dio = locator<ApiClient>().dio;

  // 更新用户信息
  Future<void> updateUserInfo(Map<String, dynamic> payload) async {
    await _dio.patch(ApiEndpoints.userInfo, data: payload);
  }

  // 上传头像
  Future<String?> uploadAvatar(XFile image) async {
    final formData = FormData.fromMap({'file': await MultipartFile.fromFile(image.path, filename: image.name)});

    final res = await _dio.post(ApiEndpoints.uploadAvatar, data: formData);
    final data = res.data;

    if (data is Map) {
      return data['avatarDisplay']?.toString() ?? data['avatar']?.toString();
    }
    return null;
  }
}
