import 'package:image_picker/image_picker.dart';
import 'package:fullxpet/common/providers/base_provider.dart';
import 'package:fullxpet/core/network/api_exception.dart';
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
  Future<void> fetchPets({String? locale}) async {
    setLoading(true);
    clearError();
    try {
      _pets = await _petRepo.getPetList(locale: locale);
      if (_selectedPet != null) {
        final idx = _pets.indexWhere((p) => p.id == _selectedPet!.id);
        _selectedPet = idx != -1 ? _pets[idx] : (_pets.isNotEmpty ? _pets.first : null);
      } else if (_pets.isNotEmpty) {
        _selectedPet = _pets.first;
      }
    } catch (e) {
      setError(ApiException.from(e).message);
    } finally {
      setLoading(false);
      notifyListeners();
    }
  }

  /// 上传头像 / 照片
  Future<PetAvatarDto?> uploadAvatar(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: source, imageQuality: 80, maxWidth: 800);
      if (image == null) return null;

      setLoading(true);
      clearError();
      return await _petRepo.uploadPetAvatar(image);
    } catch (e) {
      setError(ApiException.from(e).message);
      return null;
    } finally {
      setLoading(false);
    }
  }

  /// 新增宠物
  Future<bool> savePet({
    required String petType,
    required String name,
    required String avatarPath,
    List<String>? photoKeys,
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
      final keys = (photoKeys != null && photoKeys.isNotEmpty)
          ? photoKeys
          : (avatarPath.isNotEmpty ? [avatarPath] : const <String>[]);
      final photosList = [
        for (final k in keys) {'key': k},
      ];

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

      final createdPet = await _petRepo.createPet(payload);
      _pets.insert(0, createdPet);
      _selectedPet = createdPet;
      notifyListeners();
      return true;
    } catch (e) {
      setError(ApiException.from(e).message);
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
    required List<String> photoKeys,
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
        'photos': [
          for (final k in photoKeys) {'key': k},
        ],
        'sex': sex,
        'activeness': activeness,
        if (birth != null) 'birth': birth,
        'weight': weight,
        'breedCode': breedCode,
        'extInfo': extInfo,
      };

      final updatedPet = await _petRepo.updatePet(petId, payload);
      final index = _pets.indexWhere((p) => p.id == petId);
      if (index != -1) {
        _pets[index] = updatedPet;
        if (_selectedPet?.id == petId) {
          _selectedPet = updatedPet;
        }
        notifyListeners();
      }
      return true;
    } catch (e) {
      setError(ApiException.from(e).message);
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
      await _petRepo.deletePet(petId);
      _pets.removeWhere((p) => p.id == petId);
      if (_selectedPet?.id == petId) {
        _selectedPet = _pets.isNotEmpty ? _pets.first : null;
      }
      notifyListeners();
      return true;
    } catch (e) {
      setError(ApiException.from(e).message);
      return false;
    } finally {
      setLoading(false);
    }
  }
}
