import 'package:image_picker/image_picker.dart';
import 'package:fullxpet/common/providers/base_provider.dart';
import 'package:fullxpet/locator.dart';
import 'models/pet_dto.dart';
import 'repositories/pet_repository.dart';

class PetProvider extends BaseProvider {
  final PetRepository _petRepo = locator<PetRepository>();

  List<PetDto> _pets = [];
  List<PetDto> get pets => _pets;

  PetDto? _selectedPet;
  PetDto? get selectedPet => _selectedPet;

  void selectPet(PetDto pet) {
    _selectedPet = pet;
    notifyListeners();
  }

  /// 刷新宠物列表
  Future<void> fetchPets({String locale = 'zh'}) async {
    setLoading(true);
    clearError();
    try {
      final result = await _petRepo.getPetList(locale: locale);
      if (result.data != null) {
        _pets = result.data!;
        if (_selectedPet != null) {
          final idx = _pets.indexWhere((p) => p.id == _selectedPet!.id);
          _selectedPet = idx != -1 ? _pets[idx] : (_pets.isNotEmpty ? _pets.first : null);
        } else if (_pets.isNotEmpty) {
          _selectedPet = _pets.first;
        }
      } else {
        setError(result.message);
      }
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
      notifyListeners();
    }
  }

  /// 上传头像返回 path 与 完整 display url
  Future<Map<String, dynamic>?> uploadAvatar(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: source, imageQuality: 80, maxWidth: 800);
      if (image == null) return null;

      setLoading(true);
      clearError();
      final result = await _petRepo.uploadPetAvatar(image);
      if (result.data != null) {
        return result.data;
      } else {
        setError(result.message);
      }
    } catch (e) {
      setError('头像上传失败，请检查相机/相册权限及网络连接');
    } finally {
      setLoading(false);
    }
    return null;
  }

  /// 新增宠物
  Future<bool> savePet({
    required String petType,
    required String name,
    required String avatarPath,
    List<String>? photoKeys, // 新增：宠物其他图片 key 列表
    required int sex,
    required int activeness,
    required int? birth,
    required int weight,
    required String breedCode,
    String extInfo = '',
    String? deviceId,
  }) async {
    setLoading(true);
    clearError();
    try {
      // 组装 photos 字段：优先使用上传的宠物照片列表，为空时若存在头像则用头像兜底
      final List photosList = (photoKeys != null && photoKeys.isNotEmpty)
          ? photoKeys.map((k) => {'key': k}).toList()
          : (avatarPath.isNotEmpty
                ? [
                    {'key': avatarPath},
                  ]
                : []);

      final payload = {
        'petType': petType,
        'name': name,
        'avatar': avatarPath,
        'photos': photosList,
        'sex': sex,
        'activeness': activeness,
        if (birth != null) 'birth': birth,
        'weight': weight,
        'breedCode': breedCode,
        'extInfo': extInfo,
        if (deviceId != null && deviceId.isNotEmpty) 'deviceId': deviceId,
      };

      final result = await _petRepo.createPet(payload);
      if (result.data != null) {
        _pets.insert(0, result.data!);
        _selectedPet = result.data!;
        notifyListeners();
        return true;
      }
      setError(result.message);
      return false;
    } catch (e) {
      setError(e.toString());
      return false;
    } finally {
      setLoading(false);
    }
  }

  /// 更新宠物
  Future<bool> updatePet({
    required String petId,
    required String petType,
    required String name,
    required String avatarPath,
    required int sex,
    required int activeness,
    required int? birth,
    required int weight,
    required String breedCode,
    String extInfo = '',
  }) async {
    setLoading(true);
    clearError();
    try {
      final payload = {
        'petType': petType,
        'name': name,
        'avatar': avatarPath,
        'sex': sex,
        'activeness': activeness,
        if (birth != null) 'birth': birth,
        'weight': weight,
        'breedCode': breedCode,
        'extInfo': extInfo,
      };

      final result = await _petRepo.updatePet(petId, payload);
      if (result.data != null) {
        final index = _pets.indexWhere((p) => p.id == petId);
        if (index != -1) {
          _pets[index] = result.data!;
          if (_selectedPet?.id == petId) {
            _selectedPet = result.data!;
          }
          notifyListeners();
        }
        return true;
      }
      setError(result.message);
      return false;
    } catch (e) {
      setError(e.toString());
      return false;
    } finally {
      setLoading(false);
    }
  }

  /// 删除宠物
  Future<bool> deletePet(String petId) async {
    setLoading(true);
    clearError();
    try {
      final result = await _petRepo.deletePet(petId);
      if (result.data == true) {
        _pets.removeWhere((p) => p.id == petId);
        if (_selectedPet?.id == petId) {
          _selectedPet = _pets.isNotEmpty ? _pets.first : null;
        }
        notifyListeners();
        return true;
      }
      setError(result.message);
      return false;
    } catch (e) {
      setError(e.toString());
      return false;
    } finally {
      setLoading(false);
    }
  }
}
