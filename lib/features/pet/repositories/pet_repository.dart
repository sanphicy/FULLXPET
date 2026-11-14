import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:fullxpet/core/network/api_endpoints.dart';
import 'package:fullxpet/core/network/http_client.dart';
import 'package:fullxpet/core/network/result_model.dart';
import 'package:fullxpet/locator.dart';
import '../models/pet_dto.dart';
import 'package:image_picker/image_picker.dart';

class PetRepository {
  final HttpClient _httpClient = locator<HttpClient>();
  String? _cachedHomeId;

  // 获取当前默认家庭 ID（与项目中设备模块逻辑保持一致）
  Future<String> getDefaultHomeId() async {
    if (_cachedHomeId != null && _cachedHomeId!.isNotEmpty) {
      return _cachedHomeId!;
    }
    try {
      final homeListRes = await _httpClient.get(ApiEndpoints.homeList);
      if (homeListRes.data != null && homeListRes.data!['items'] != null) {
        final items = homeListRes.data!['items'] as List;
        if (items.isNotEmpty) {
          _cachedHomeId = items[0]['id']?.toString() ?? '';
          return _cachedHomeId!;
        }
      }
    } catch (e) {
      debugPrint('[PetRepository] 获取家庭 ID 失败: $e');
    }
    return '';
  }

  // 获取宠物列表
  Future<ResultEntity<List<PetDto>>> getPetList({String locale = 'zh'}) async {
    try {
      final homeId = await getDefaultHomeId();
      if (homeId.isEmpty) return ResultEntity.error('未找到有效的家庭信息');

      final response = await _httpClient.get(ApiEndpoints.pets(homeId), query: {'locale': locale});

      if (response.data != null && (response.code == 0 || response.code == 200)) {
        final petsRaw = response.data!['pets'] as List? ?? [];
        final pets = petsRaw.map((e) => PetDto.fromJson(e as Map<String, dynamic>)).toList();
        return ResultEntity.success(pets);
      }
      return ResultEntity.error(response.message);
    } catch (e) {
      return ResultEntity.error('获取宠物列表失败: $e');
    }
  }

  // 上传宠物头像 ResultEntit
  Future<ResultEntity> uploadPetAvatar(XFile image) async {
    try {
      final homeId = await getDefaultHomeId();
      if (homeId.isEmpty) return ResultEntity.error('未找到有效的家庭信息');

      final formData = FormData.fromMap({'file': await MultipartFile.fromFile(image.path, filename: image.name)});

      final response = await _httpClient.post(ApiEndpoints.petAvatar(homeId), data: formData);
      if (response.data != null && (response.code == 0 || response.code == 200)) {
        final data = response.data!;
        final avatar = data['avatar']?.toString() ?? '';
        final avatarDisplay = data['avatarDisplay']?.toString() ?? avatar;
        return ResultEntity.success({'avatar': avatar, 'avatarDisplay': avatarDisplay});
      }
      return ResultEntity.error(response.message);
    } catch (e) {
      return ResultEntity.error('头像上传失败，请检查相机/相册权限及网络连接');
    }
  }

  /// 创建宠物
  Future<ResultEntity<PetDto>> createPet(Map<String, dynamic> payload) async {
    try {
      final homeId = await getDefaultHomeId();
      if (homeId.isEmpty) return ResultEntity.error('未找到有效的家庭信息');

      final response = await _httpClient.post(ApiEndpoints.addPet(homeId), data: payload);
      if (response.data != null && (response.code == 0 || response.code == 200)) {
        return ResultEntity.success(PetDto.fromJson(response.data!));
      }
      return ResultEntity.error(response.message);
    } catch (e) {
      return ResultEntity.error('创建宠物失败: $e');
    }
  }

  /// 修改宠物资料
  Future<ResultEntity<PetDto>> updatePet(String petId, Map<String, dynamic> payload) async {
    try {
      final homeId = await getDefaultHomeId();
      if (homeId.isEmpty) return ResultEntity.error('未找到有效的家庭信息');

      final response = await _httpClient.patch(ApiEndpoints.updatePetInfo(homeId, petId), data: payload);
      if (response.data != null && (response.code == 0 || response.code == 200)) {
        return ResultEntity.success(PetDto.fromJson(response.data!));
      }
      return ResultEntity.error(response.message);
    } catch (e) {
      return ResultEntity.error('更新宠物资料失败: $e');
    }
  }

  /// 删除宠物
  Future<ResultEntity<bool>> deletePet(String petId) async {
    try {
      final homeId = await getDefaultHomeId();
      if (homeId.isEmpty) return ResultEntity.error('未找到有效的家庭信息');

      final response = await _httpClient.delete(ApiEndpoints.deletePet(homeId, petId));
      if (response.code == 0 || response.code == 200) {
        return ResultEntity.success(true);
      }
      return ResultEntity.error(response.message);
    } catch (e) {
      return ResultEntity.error('删除宠物失败: $e');
    }
  }
}
