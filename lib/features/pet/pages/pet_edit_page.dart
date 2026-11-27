import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:fullxpet/common/l10n/app_localizations.dart';
import 'package:fullxpet/common/theme/app_theme.dart';
import 'package:fullxpet/common/widgets/app_avatar.dart';
import 'package:fullxpet/common/widgets/app_dialogs.dart';
import 'package:fullxpet/common/widgets/responsive_layout.dart';
import 'package:fullxpet/features/device/device_provider.dart';
import 'package:fullxpet/features/device/models/device_item_dto.dart';
import '../models/pet_dto.dart';
import '../pet_provider.dart';
import '../widgets/breed_picker_sheet.dart';

class PetEditPage extends StatefulWidget {
  final PetDto? initialPet;
  const PetEditPage({super.key, this.initialPet});

  @override
  State<PetEditPage> createState() => _PetEditPageState();
}

class _PetEditPageState extends State<PetEditPage> {
  static const Color _primaryPurple = AppTheme.primaryPurple;

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _weightCtrl = TextEditingController();
  final TextEditingController _extInfoCtrl = TextEditingController();

  String _petType = 'cat';
  int _sex = 1;
  int _activeness = 1;
  int? _birthTimestamp;
  String _avatarPath = '';
  String _avatarDisplay = '';
  String _breedCode = '';
  String _breedName = '';
  bool _isSaving = false;
  String? _selectedDeviceId;

  bool get _isEditMode => widget.initialPet != null;

  @override
  void initState() {
    super.initState();
    final p = widget.initialPet;
    if (p != null) {
      _nameCtrl.text = p.name;
      _weightCtrl.text = (p.weight / 1000.0).toStringAsFixed(1);
      _extInfoCtrl.text = p.extInfo;
      _petType = p.petType;
      _sex = p.sex;
      _activeness = p.activeness;
      _birthTimestamp = p.birth;
      _avatarPath = p.avatar;
      _avatarDisplay = p.avatarDisplay;
      _breedCode = p.breedCode;
      _breedName = p.breedName;
      _photos.addAll(p.photos);
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.read<DeviceProvider>().fetchDevices();
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _weightCtrl.dispose();
    _extInfoCtrl.dispose();
    super.dispose();
  }

  void _onPetTypeChanged(String newType) {
    if (_petType == newType) return;
    setState(() {
      _petType = newType;
      _breedCode = '';
      _breedName = '';
    });
  }

  Future<void> _openBreedPicker() async {
    final selected = await BreedPickerSheet.show(context, petType: _petType, selectedBreedCode: _breedCode);
    if (selected != null && mounted) {
      setState(() {
        _breedCode = selected.breedCode;
        _breedName = selected.breedName;
      });
    }
  }

  void _showImagePicker({bool isAvatar = true}) {
    final s = S.of(context)!;
    final provider = context.read<PetProvider>();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text(s.chooseFromGallery),
                onTap: () async {
                  Navigator.pop(ctx);
                  if (isAvatar) {
                    await _handleAvatarUpload(provider, ImageSource.gallery, s);
                  } else {
                    await _handlePhotoUpload(provider, ImageSource.gallery, s);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: Text(s.takePhoto),
                onTap: () async {
                  Navigator.pop(ctx);
                  if (isAvatar) {
                    await _handleAvatarUpload(provider, ImageSource.camera, s);
                  } else {
                    await _handlePhotoUpload(provider, ImageSource.camera, s);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // 1. 状态字段声明
  final List<PetPhotoDto> _photos = [];
  // 2. _handleAvatarUpload
  Future<void> _handleAvatarUpload(PetProvider provider, ImageSource source, S s) async {
    final uploadRes = await provider.uploadAvatar(source);
    if (!mounted) return;

    if (uploadRes != null) {
      setState(() {
        _avatarPath = uploadRes.avatar;
        _avatarDisplay = uploadRes.avatarDisplay;
      });
      context.showAppToast(message: s.operationSuccess, type: AppToastType.success);
    } else if (provider.errorMsg.isNotEmpty) {
      context.showAppToast(message: provider.errorMsg, type: AppToastType.error);
    }
  }

  // 3. _handlePhotoUpload
  Future<void> _handlePhotoUpload(PetProvider provider, ImageSource source, S s) async {
    final uploadRes = await provider.uploadAvatar(source);
    if (!mounted) return;

    if (uploadRes != null && uploadRes.avatar.isNotEmpty) {
      setState(() {
        _photos.add(PetPhotoDto(key: uploadRes.avatar, url: uploadRes.avatarDisplay));
      });
      context.showAppToast(message: s.operationSuccess, type: AppToastType.success);
    } else if (provider.errorMsg.isNotEmpty) {
      context.showAppToast(message: provider.errorMsg, type: AppToastType.error);
    }
  }

  void _showDevicePickerDialog(BuildContext context, List<DeviceItemDto> devices) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  '选择要绑定的设备',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  physics: const ClampingScrollPhysics(),
                  children: [
                    ListTile(
                      leading: const Icon(Icons.link_off_rounded, color: Colors.grey),
                      title: const Text('不绑定设备'),
                      trailing: (_selectedDeviceId == null || _selectedDeviceId!.isEmpty)
                          ? const Icon(Icons.check, color: _primaryPurple)
                          : null,
                      onTap: () {
                        setState(() => _selectedDeviceId = null);
                        Navigator.pop(ctx);
                      },
                    ),
                    if (devices.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Center(
                          child: Text('暂无可用设备', style: TextStyle(color: Colors.grey, fontSize: 13)),
                        ),
                      )
                    else
                      ...devices.map((d) {
                        final isSelected = _selectedDeviceId == d.deviceId;
                        return ListTile(
                          leading: const Icon(Icons.devices_rounded, color: _primaryPurple),
                          title: Text(d.nickname),
                          subtitle: Text('ID: ${context.read<DeviceProvider>().resolveDisplayId(d)}'),
                          trailing: isSelected ? const Icon(Icons.check, color: _primaryPurple) : null,
                          onTap: () {
                            setState(() => _selectedDeviceId = d.deviceId);
                            Navigator.pop(ctx);
                          },
                        );
                      }),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final initialDate = _birthTimestamp != null
        ? DateTime.fromMillisecondsSinceEpoch(_birthTimestamp!)
        : DateTime(now.year - 1, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: now,
      helpText: '选择宠物出生日期',
    );
    if (picked != null) {
      setState(() {
        _birthTimestamp = picked.toUtc().millisecondsSinceEpoch;
      });
    }
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      context.showAppToast(message: '请输入宠物昵称', type: AppToastType.warning);
      return;
    }
    if (_breedCode.isEmpty) {
      context.showAppToast(message: '请选择宠物品种', type: AppToastType.warning);
      return;
    }

    final weightKg = double.tryParse(_weightCtrl.text.trim()) ?? 0.0;
    final weightGrams = (weightKg * 1000).round();

    setState(() => _isSaving = true);
    final provider = context.read<PetProvider>();
    bool ok;
    if (_isEditMode) {
      ok = await provider.updatePet(
        petId: widget.initialPet!.id,
        petType: _petType,
        name: name,
        avatarPath: _avatarPath,
        photoKeys: _photos.map((e) => e.key).toList(),
        sex: _sex,
        activeness: _activeness,
        birth: _birthTimestamp,
        weight: weightGrams,
        breedCode: _breedCode,
        extInfo: _extInfoCtrl.text.trim(),
      );
    } else {
      ok = await provider.savePet(
        petType: _petType,
        name: name,
        avatarPath: _avatarPath,
        photoKeys: _photos.map((e) => e.key).toList(),
        sex: _sex,
        activeness: _activeness,
        birth: _birthTimestamp,
        weight: weightGrams,
        breedCode: _breedCode,
        extInfo: _extInfoCtrl.text.trim(),
        deviceId: _selectedDeviceId,
      );
    }

    if (mounted) {
      setState(() => _isSaving = false);
      if (ok) {
        context.showAppToast(message: S.of(context)!.operationSuccess, type: AppToastType.success);
        context.pop();
      } else {
        context.showAppToast(
          message: provider.errorMsg.isNotEmpty ? provider.errorMsg : '保存失败',
          type: AppToastType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final linkedDevices = widget.initialPet?.linkedDevices ?? const <LinkedDeviceDto>[];

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FC),
      appBar: AppBar(
        title: Text(
          _isEditMode ? '编辑宠物' : '添加宠物',
          style: const TextStyle(color: Color(0xFF222222), fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: ResponsiveFormContainer(
          maxWidth: 600,
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: GestureDetector(
                    onTap: () => _showImagePicker(isAvatar: true),
                    child: Stack(
                      children: [
                        AppAvatar(avatarUrl: _avatarDisplay, radius: 46),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(color: _primaryPurple, shape: BoxShape.circle),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: _buildChoiceCard('猫咪', Icons.pets, _petType == 'cat', () => _onPetTypeChanged('cat')),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _buildChoiceCard(
                        '狗狗',
                        Icons.cruelty_free,
                        _petType == 'dog',
                        () => _onPetTypeChanged('dog'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                _buildCardGroup(
                  children: [
                    _buildTextFieldItem('名字', '请输入宠物名字', _nameCtrl),
                    const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFF0EFF5)),
                    ListTile(
                      title: const Text('品种', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 180),
                            child: Text(
                              _breedName.isNotEmpty ? _breedName : (_breedCode.isNotEmpty ? _breedCode : '请选择品种'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: _breedCode.isNotEmpty ? const Color(0xFF333333) : Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey, size: 14),
                        ],
                      ),
                      onTap: _openBreedPicker,
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFF0EFF5)),
                    _buildTextFieldItem(
                      '体重 (kg)',
                      '例如：4.5',
                      _weightCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFF0EFF5)),
                    ListTile(
                      title: const Text('生日', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _birthTimestamp != null
                                ? DateTime.fromMillisecondsSinceEpoch(_birthTimestamp!).toString().split(' ').first
                                : '请选择生日',
                            style: TextStyle(
                              color: _birthTimestamp != null ? const Color(0xFF333333) : Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey, size: 14),
                        ],
                      ),
                      onTap: _pickBirthDate,
                    ),
                    if (!_isEditMode) ...[
                      const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFF0EFF5)),
                      Consumer<DeviceProvider>(
                        builder: (context, deviceProvider, _) {
                          final devices = deviceProvider.devices;
                          final selectedDevice = devices.firstWhere(
                            (d) => d.deviceId == _selectedDeviceId,
                            orElse: () => const DeviceItemDto(deviceId: '', productId: '', nickname: '不绑定设备'),
                          );

                          return ListTile(
                            title: const Text('绑定设备', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  (_selectedDeviceId == null || _selectedDeviceId!.isEmpty)
                                      ? '不绑定'
                                      : (selectedDevice.nickname.isNotEmpty
                                            ? selectedDevice.nickname
                                            : _selectedDeviceId!),
                                  style: TextStyle(
                                    color: (_selectedDeviceId != null && _selectedDeviceId!.isNotEmpty)
                                        ? const Color(0xFF333333)
                                        : Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey, size: 14),
                              ],
                            ),
                            onTap: () => _showDevicePickerDialog(context, devices),
                          );
                        },
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),

                // 编辑模式：只读回显已绑定设备（PATCH 接口不支持修改设备绑定）
                if (_isEditMode) ...[
                  // 宠物照片卡片（新增与编辑模式共用）
                  _buildCardGroup(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                        child: Text(
                          '宠物照片',
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            ..._photos.asMap().entries.map((entry) {
                              final index = entry.key;
                              final url = entry.value.url;
                              return Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      url,
                                      width: 76,
                                      height: 76,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        width: 76,
                                        height: 76,
                                        color: const Color(0xFFF0EFF5),
                                        child: const Icon(Icons.pets, color: Colors.grey),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: -6,
                                    right: -6,
                                    child: GestureDetector(
                                      onTap: () => setState(() => _photos.removeAt(index)),
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                        child: const Icon(Icons.close, color: Colors.white, size: 14),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }),
                            GestureDetector(
                              onTap: () => _showImagePicker(isAvatar: false),
                              child: Container(
                                width: 76,
                                height: 76,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF9F9FC),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFE5E5E5), width: 1.5),
                                ),
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_photo_alternate_outlined, color: _primaryPurple, size: 26),
                                    SizedBox(height: 4),
                                    Text('上传照片', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // 新增模式：宠物照片上传卡片
                if (!_isEditMode) ...[
                  _buildCardGroup(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                        child: Text(
                          '宠物照片',
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            ..._photos.asMap().entries.map((entry) {
                              final index = entry.key;
                              final url = entry.value.url;
                              return Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      url,
                                      width: 76,
                                      height: 76,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        width: 76,
                                        height: 76,
                                        color: const Color(0xFFF0EFF5),
                                        child: const Icon(Icons.pets, color: Colors.grey),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: -6,
                                    right: -6,
                                    child: GestureDetector(
                                      onTap: () => setState(() => _photos.removeAt(index)),
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                        child: const Icon(Icons.close, color: Colors.white, size: 14),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }),
                            GestureDetector(
                              onTap: () => _showImagePicker(isAvatar: false),
                              child: Container(
                                width: 76,
                                height: 76,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF9F9FC),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFE5E5E5), width: 1.5),
                                ),
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_photo_alternate_outlined, color: _primaryPurple, size: 26),
                                    SizedBox(height: 4),
                                    Text('上传照片', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                _buildCardGroup(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                      child: Text(
                        '性别',
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: Wrap(
                        spacing: 8,
                        children: PetSex.values.map((s) {
                          final selected = _sex == s.value;
                          return ChoiceChip(
                            label: Text(s.label),
                            selected: selected,
                            selectedColor: _primaryPurple.withValues(alpha: 0.15),
                            labelStyle: TextStyle(
                              color: selected ? _primaryPurple : const Color(0xFF555555),
                              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 12,
                            ),
                            onSelected: (_) => setState(() => _sex = s.value),
                          );
                        }).toList(),
                      ),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFF0EFF5)),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                      child: Text(
                        '活跃程度',
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
                      child: Wrap(
                        spacing: 8,
                        children: PetActiveness.values.map((a) {
                          final selected = _activeness == a.value;
                          return ChoiceChip(
                            label: Text(a.label),
                            selected: selected,
                            selectedColor: _primaryPurple.withValues(alpha: 0.15),
                            labelStyle: TextStyle(
                              color: selected ? _primaryPurple : const Color(0xFF555555),
                              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 12,
                            ),
                            onSelected: (_) => setState(() => _activeness = a.value),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                _buildCardGroup(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                      child: Text(
                        '备注信息',
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: TextField(
                        controller: _extInfoCtrl,
                        minLines: 2,
                        maxLines: 4,
                        maxLength: 200,
                        style: const TextStyle(fontSize: 14, color: Color(0xFF333333)),
                        decoration: const InputDecoration(
                          hintText: '选填，如饮食习惯、过敏史等',
                          hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                          border: InputBorder.none,
                          counterStyle: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryPurple,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      elevation: 0,
                    ),
                    onPressed: _isSaving ? null : _submit,
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text(
                            '保存',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChoiceCard(String label, IconData icon, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? _primaryPurple.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? _primaryPurple : const Color(0xFFE5E5E5), width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: selected ? _primaryPurple : Colors.grey, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                color: selected ? _primaryPurple : const Color(0xFF555555),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardGroup({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _buildTextFieldItem(
    String title,
    String hint,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF333333)),
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              textAlign: TextAlign.end,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
