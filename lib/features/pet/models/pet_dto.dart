/// 宠物照片 DTO（对应接口返回的 photos 元素）
class PetPhotoDto {
  final String key;
  final String url;

  const PetPhotoDto({required this.key, required this.url});

  factory PetPhotoDto.fromJson(Map<String, dynamic> json) {
    final key = json['key']?.toString() ?? '';
    final url = json['url']?.toString() ?? '';
    return PetPhotoDto(key: key, url: url.isNotEmpty ? url : key);
  }
}

// 宠物图片上传结果 DTO（对应 POST /pets/avatar）
class PetAvatarDto {
  final String avatar;
  final String avatarDisplay;

  const PetAvatarDto({required this.avatar, required this.avatarDisplay});

  factory PetAvatarDto.fromJson(Map<String, dynamic> json) {
    final avatar = json['avatar']?.toString() ?? '';
    final display = json['avatarDisplay']?.toString() ?? '';
    return PetAvatarDto(avatar: avatar, avatarDisplay: display.isNotEmpty ? display : avatar);
  }
}

/// 宠物品种 DTO
class PetBreedDto {
  final String id;
  final String breedCode;
  final String breedName;
  final String letterIndex;
  final String petType;

  const PetBreedDto({
    this.id = '',
    required this.breedCode,
    required this.breedName,
    this.letterIndex = '',
    this.petType = '',
  });

  factory PetBreedDto.fromJson(Map<String, dynamic> json) {
    return PetBreedDto(
      id: json['id']?.toString() ?? '',
      breedCode: json['breedCode']?.toString() ?? '',
      breedName: json['breedName']?.toString() ?? '',
      letterIndex: json['letterIndex']?.toString() ?? '',
      petType: json['petType']?.toString() ?? '',
    );
  }
}

/// 宠物性别枚举
enum PetSex {
  female(0, '雌性'),
  male(1, '雄性'),
  neuteredFemale(2, '已绝育雌性'),
  neuteredMale(3, '已绝育雄性');

  final int value;
  final String label;
  const PetSex(this.value, this.label);

  static PetSex fromValue(int? val) {
    return PetSex.values.firstWhere((e) => e.value == val, orElse: () => PetSex.male);
  }
}

/// 活跃度枚举
enum PetActiveness {
  low(0, '不活跃'),
  normal(1, '正常'),
  high(2, '非常活跃');

  final int value;
  final String label;
  const PetActiveness(this.value, this.label);

  static PetActiveness fromValue(int? val) {
    return PetActiveness.values.firstWhere((e) => e.value == val, orElse: () => PetActiveness.normal);
  }
}

/// 绑定的智能设备
class LinkedDeviceDto {
  final String deviceId;
  final String pgDeviceId;
  final String nickname;
  final String productId;
  final String linkType;
  final bool isPrimary;
  final bool isDefaultOnDevice;
  final int linkedAt;

  LinkedDeviceDto({
    required this.deviceId,
    this.pgDeviceId = '',
    this.nickname = '',
    this.productId = '',
    this.linkType = '',
    this.isPrimary = false,
    this.isDefaultOnDevice = false,
    this.linkedAt = 0,
  });

  factory LinkedDeviceDto.fromJson(Map<String, dynamic> json) {
    return LinkedDeviceDto(
      deviceId: json['deviceId']?.toString() ?? '',
      pgDeviceId: json['pgDeviceId']?.toString() ?? '',
      nickname: json['nickname']?.toString() ?? '',
      productId: json['productId']?.toString() ?? '',
      linkType: json['linkType']?.toString() ?? '',
      isPrimary: json['isPrimary'] == true,
      isDefaultOnDevice: json['isDefaultOnDevice'] == true,
      linkedAt: int.tryParse(json['linkedAt']?.toString() ?? '') ?? 0,
    );
  }
}

/// 宠物信息 DTO
class PetDto {
  final String id;
  final String ownerId;
  final String petType; // 'cat' | 'dog'
  final String name;
  final String avatar;
  final String avatarDisplay;
  final List<PetPhotoDto> photos;
  final int sex;
  final int activeness;
  final int? birth; // UTC 毫秒时间戳
  final int weight; // 重量：单位克(g)
  final String breedCode;
  final String breedName;
  final String extInfo;
  final bool bindFood;
  final bool bindLitter;
  final List<LinkedDeviceDto> linkedDevices;

  PetDto({
    required this.id,
    this.ownerId = '',
    this.petType = 'cat',
    this.name = '',
    this.avatar = '',
    this.avatarDisplay = '',
    List<PetPhotoDto>? photos,
    this.sex = 1,
    this.activeness = 1,
    this.birth,
    this.weight = 0,
    this.breedCode = '',
    this.breedName = '',
    this.extInfo = '',
    this.bindFood = false,
    this.bindLitter = false,
    List<LinkedDeviceDto>? linkedDevices,
  }) : photos = photos ?? [],
       linkedDevices = linkedDevices ?? [];

  PetSex get petSex => PetSex.fromValue(sex);
  PetActiveness get petActiveness => PetActiveness.fromValue(activeness);

  String get weightKgStr => (weight / 1000.0).toStringAsFixed(1);

  String get ageStr {
    if (birth == null || birth! <= 0) return '未知';
    final birthDate = DateTime.fromMillisecondsSinceEpoch(birth!, isUtc: true).toLocal();
    final now = DateTime.now();
    int years = now.year - birthDate.year;
    int months = now.month - birthDate.month;
    if (now.day < birthDate.day) months--;
    if (months < 0) {
      years--;
      months += 12;
    }
    if (years <= 0) {
      return months <= 0 ? '不到1个月' : '$months 个月';
    }
    return months > 0 ? '$years 岁 $months 个月' : '$years 岁';
  }

  factory PetDto.fromJson(Map<String, dynamic> json) {
    final photoList = json['photos'] as List?;
    final linkedList = json['linkedDevices'] as List?;
    return PetDto(
      id: json['id']?.toString() ?? '',
      ownerId: json['ownerId']?.toString() ?? '',
      petType: json['petType']?.toString() ?? 'cat',
      name: json['name']?.toString() ?? '',
      avatar: json['avatar']?.toString() ?? '',
      avatarDisplay: json['avatarDisplay']?.toString() ?? '',
      photos: [
        if (photoList != null)
          for (final e in photoList)
            if (e is Map<String, dynamic>) PetPhotoDto.fromJson(e),
      ],
      sex: int.tryParse(json['sex']?.toString() ?? '') ?? 1,
      activeness: int.tryParse(json['activeness']?.toString() ?? '') ?? 1,
      birth: json['birth'] != null ? int.tryParse(json['birth'].toString()) : null,
      weight: int.tryParse(json['weight']?.toString() ?? '') ?? 0,
      breedCode: json['breedCode']?.toString() ?? '',
      breedName: json['breedName']?.toString() ?? '',
      extInfo: json['extInfo']?.toString() ?? '',
      bindFood: json['bindFood'] == true,
      bindLitter: json['bindLitter'] == true,
      linkedDevices: [
        if (linkedList != null)
          for (final e in linkedList)
            if (e is Map<String, dynamic>) LinkedDeviceDto.fromJson(e),
      ],
    );
  }

  PetDto copyWith({
    String? id,
    String? ownerId,
    String? petType,
    String? name,
    String? avatar,
    String? avatarDisplay,
    List<PetPhotoDto>? photos,
    int? sex,
    int? activeness,
    int? birth,
    int? weight,
    String? breedCode,
    String? breedName,
    String? extInfo,
    bool? bindFood,
    bool? bindLitter,
    List<LinkedDeviceDto>? linkedDevices,
  }) {
    return PetDto(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      petType: petType ?? this.petType,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      avatarDisplay: avatarDisplay ?? this.avatarDisplay,
      photos: photos ?? this.photos,
      sex: sex ?? this.sex,
      activeness: activeness ?? this.activeness,
      birth: birth ?? this.birth,
      weight: weight ?? this.weight,
      breedCode: breedCode ?? this.breedCode,
      breedName: breedName ?? this.breedName,
      extInfo: extInfo ?? this.extInfo,
      bindFood: bindFood ?? this.bindFood,
      bindLitter: bindLitter ?? this.bindLitter,
      linkedDevices: linkedDevices ?? this.linkedDevices,
    );
  }
}
