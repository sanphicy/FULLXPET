import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fullxpet/common/providers/locale_provider.dart';
import 'package:fullxpet/core/network/api_client.dart';
import 'package:fullxpet/core/network/api_endpoints.dart';
import 'package:fullxpet/core/network/api_exception.dart';
import 'package:fullxpet/locator.dart';
import '../models/pet_dto.dart';

class PetRepository {
  final Dio _dio = locator<ApiClient>().dio;
  String? _cachedHomeId;
  final Map<String, List<PetBreedDto>> _breedCache = {};

  String _resolveLocale(String? locale) {
    if (locale != null && locale.isNotEmpty) return locale;
    return locator<LocaleProvider>().apiLocale;
  }

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
  Future<List<PetDto>> getPetList({String? locale}) async {
    final homeId = await getDefaultHomeId();
    if (homeId.isEmpty) {
      throw const ApiException(message: '未找到有效的家庭信息');
    }

    final res = await _dio.get(ApiEndpoints.pets(homeId), queryParameters: {'locale': _resolveLocale(locale)});

    final data = res.data;
    final petsRaw = (data is Map<String, dynamic> ? data['pets'] : null) as List? ?? [];
    return [
      for (final e in petsRaw)
        if (e is Map<String, dynamic>) PetDto.fromJson(e),
    ];
  }

  /// 获取品种字典（按类型与语言缓存在数据层，不污染全局 PetProvider 状态）
  Future<List<PetBreedDto>> getBreeds({required String petType, String? locale, bool forceRefresh = false}) async {
    final resolvedLocale = _resolveLocale(locale);
    final cacheKey = '${petType}_$resolvedLocale';
    if (!forceRefresh && _breedCache.containsKey(cacheKey)) {
      return _breedCache[cacheKey]!;
    }

    final res = await _dio.get(ApiEndpoints.breeds, queryParameters: {'petType': petType, 'locale': resolvedLocale});
    final data = res.data;
    final breedsRaw = (data is Map<String, dynamic> ? data['breeds'] : null) as List? ?? [];
    final list = [
      for (final e in breedsRaw)
        if (e is Map<String, dynamic>) PetBreedDto.fromJson(e),
    ];
    _breedCache[cacheKey] = list;
    return list;
  }

  /// 上传宠物头像 / 照片
  Future<PetAvatarDto> uploadPetAvatar(XFile image) async {
    final homeId = await getDefaultHomeId();
    if (homeId.isEmpty) {
      throw const ApiException(message: '未找到有效的家庭信息');
    }

    final formData = FormData.fromMap({'file': await MultipartFile.fromFile(image.path, filename: image.name)});
    final res = await _dio.post(ApiEndpoints.petAvatar(homeId), data: formData);
    final data = res.data is Map<String, dynamic> ? res.data as Map<String, dynamic> : const <String, dynamic>{};
    return PetAvatarDto.fromJson(data);
  }

  /// 创建宠物
  Future<PetDto> createPet(Map<String, dynamic> payload) async {
    final homeId = await getDefaultHomeId();
    if (homeId.isEmpty) {
      throw const ApiException(message: '未找到有效的家庭信息');
    }

    final res = await _dio.post(ApiEndpoints.addPet(homeId), data: payload);
    return PetDto.fromJson(res.data as Map<String, dynamic>);
  }

  /// 修改宠物资料
  Future<PetDto> updatePet(String petId, Map<String, dynamic> payload) async {
    final homeId = await getDefaultHomeId();
    if (homeId.isEmpty) {
      throw const ApiException(message: '未找到有效的家庭信息');
    }

    final res = await _dio.patch(ApiEndpoints.updatePetInfo(homeId, petId), data: payload);
    return PetDto.fromJson(res.data as Map<String, dynamic>);
  }

  /// 删除宠物
  Future<void> deletePet(String petId) async {
    final homeId = await getDefaultHomeId();
    if (homeId.isEmpty) {
      throw const ApiException(message: '未找到有效的家庭信息');
    }

    await _dio.delete(ApiEndpoints.deletePet(homeId, petId));
  }
}
