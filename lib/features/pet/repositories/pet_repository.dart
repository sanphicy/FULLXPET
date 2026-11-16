import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fullxpet/core/network/api_client.dart';
import 'package:fullxpet/core/network/api_endpoints.dart';
import 'package:fullxpet/core/network/api_exception.dart';
import 'package:fullxpet/locator.dart';
import '../models/pet_dto.dart';

class PetRepository {
  final Dio _dio = locator<ApiClient>().dio;
  String? _cachedHomeId;

  // 获取当前默认家庭 ID（与项目中设备模块逻辑保持一致）
  Future<String> getDefaultHomeId() async {
    if (_cachedHomeId != null && _cachedHomeId!.isNotEmpty) {
      return _cachedHomeId!;
    }
    try {
      final res = await _dio.get(ApiEndpoints.homeList);
      final data = res.data;
      if (data is Map<String, dynamic> && data['items'] is List) {
        final items = data['items'] as List;
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
  Future<List<PetDto>> getPetList({String locale = 'zh'}) async {
    final homeId = await getDefaultHomeId();
    if (homeId.isEmpty) {
      throw const ApiException(message: '未找到有效的家庭信息');
    }

    final res = await _dio.get(ApiEndpoints.pets(homeId), queryParameters: {'locale': locale});

    final data = res.data;
    final petsRaw = (data is Map<String, dynamic> ? data['pets'] : null) as List? ?? [];
    return petsRaw.map((e) => PetDto.fromJson(e as Map<String, dynamic>)).toList();
  }

  // 上传宠物头像
  Future uploadPetAvatar(XFile image) async {
    final homeId = await getDefaultHomeId();
    if (homeId.isEmpty) {
      throw const ApiException(message: '未找到有效的家庭信息');
    }

    final formData = FormData.fromMap({'file': await MultipartFile.fromFile(image.path, filename: image.name)});

    final res = await _dio.post(ApiEndpoints.petAvatar(homeId), data: formData);
    final data = res.data as Map<String, dynamic>? ?? {};
    final avatar = data['avatar']?.toString() ?? '';
    final avatarDisplay = data['avatarDisplay']?.toString() ?? avatar;
    return {'avatar': avatar, 'avatarDisplay': avatarDisplay};
  }

  // 创建宠物
  Future<PetDto> createPet(Map<String, dynamic> payload) async {
    final homeId = await getDefaultHomeId();
    if (homeId.isEmpty) {
      throw const ApiException(message: '未找到有效的家庭信息');
    }

    final res = await _dio.post(ApiEndpoints.addPet(homeId), data: payload);
    return PetDto.fromJson(res.data as Map<String, dynamic>);
  }

  // 修改宠物资料
  Future<PetDto> updatePet(String petId, Map<String, dynamic> payload) async {
    final homeId = await getDefaultHomeId();
    if (homeId.isEmpty) {
      throw const ApiException(message: '未找到有效的家庭信息');
    }

    final res = await _dio.patch(ApiEndpoints.updatePetInfo(homeId, petId), data: payload);
    return PetDto.fromJson(res.data as Map<String, dynamic>);
  }

  // 删除宠物
  Future<void> deletePet(String petId) async {
    final homeId = await getDefaultHomeId();
    if (homeId.isEmpty) {
      throw const ApiException(message: '未找到有效的家庭信息');
    }

    await _dio.delete(ApiEndpoints.deletePet(homeId, petId));
  }
}
