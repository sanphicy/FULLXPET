import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:fullxpet/common/config/app_constants.dart';
import 'package:fullxpet/common/l10n/app_localizations.dart';
import 'package:fullxpet/common/theme/app_theme.dart';
import 'package:fullxpet/common/widgets/app_dialogs.dart';
import 'package:fullxpet/common/widgets/responsive_layout.dart';
import 'package:fullxpet/core/network/api_exception.dart';
import 'package:fullxpet/features/device/device_provider.dart';
import 'package:fullxpet/features/device/models/device_item_dto.dart';
import 'package:fullxpet/locator.dart';
import 'package:fullxpet/routes/app_router.dart';
import '../models/feedback_dto.dart';
import '../repositories/feedback_repository.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  static const Color _primaryPurple = AppTheme.primaryPurple;
  static const int _maxAttachments = 6;

  final FeedbackRepository _repo = locator<FeedbackRepository>();
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _bodyCtrl = TextEditingController();

  FeedbackKind _kind = FeedbackKind.general;
  DeviceItemDto? _selectedDevice;
  final List<FeedbackAttachmentDto> _attachments = [];
  bool _isUploading = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  void _onKindChanged(FeedbackKind kind) {
    if (_kind == kind) return;
    setState(() {
      _kind = kind;
      if (kind == FeedbackKind.general) {
        _selectedDevice = null;
      }
    });
    if (kind == FeedbackKind.device) {
      final deviceProvider = context.read<DeviceProvider>();
      if (deviceProvider.devices.isEmpty) {
        deviceProvider.fetchDevices();
      }
    }
  }

  void _showDevicePicker(List<DeviceItemDto> devices) {
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
                padding: EdgeInsets.all(16),
                child: Text(
                  '选择关联设备',
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
                      title: const Text('不指定设备'),
                      trailing: _selectedDevice == null ? const Icon(Icons.check, color: _primaryPurple) : null,
                      onTap: () {
                        setState(() => _selectedDevice = null);
                        Navigator.pop(ctx);
                      },
                    ),
                    if (devices.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: Text('暂无可用设备', style: TextStyle(color: Colors.grey, fontSize: 13)),
                        ),
                      )
                    else
                      ...devices.map((d) {
                        final selected = _selectedDevice?.deviceId == d.deviceId;
                        final displayId = context.read<DeviceProvider>().resolveDisplayId(d);
                        return ListTile(
                          leading: const Icon(Icons.devices_rounded, color: _primaryPurple),
                          title: Text(d.nickname.isNotEmpty ? d.nickname : displayId),
                          subtitle: Text('ID: $displayId'),
                          trailing: selected ? const Icon(Icons.check, color: _primaryPurple) : null,
                          onTap: () {
                            setState(() => _selectedDevice = d);
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

  void _showImagePicker(S s) {
    if (_isUploading) return;
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
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndUploadImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: Text(s.takePhoto),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndUploadImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    final XFile? image;
    try {
      final picker = ImagePicker();
      image = await picker.pickImage(source: source, imageQuality: 80, maxWidth: 1280);
    } catch (_) {
      return;
    }
    if (image == null || !mounted) return;

    setState(() => _isUploading = true);
    try {
      final attachment = await _repo.uploadImage(image);
      if (!mounted) return;
      setState(() {
        _attachments.add(attachment);
        _isUploading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploading = false);
      context.showAppToast(message: ApiException.from(e).message, type: AppToastType.error);
    }
  }

  Future<void> _submit() async {
    final title = _titleCtrl.text.trim();
    final body = _bodyCtrl.text.trim();
    if (title.isEmpty) {
      context.showAppToast(message: '请输入反馈标题', type: AppToastType.warning);
      return;
    }
    if (body.isEmpty) {
      context.showAppToast(message: '请详细描述您遇到的问题或建议', type: AppToastType.warning);
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _isSubmitting = true);
    try {
      await _repo.createFeedback(
        kind: _kind,
        title: title,
        body: body,
        deviceId: _kind == FeedbackKind.device ? _selectedDevice?.deviceId : null,
        productId: _kind == FeedbackKind.device ? _selectedDevice?.productId : null,
        attachments: _attachments,
      );
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _titleCtrl.clear();
        _bodyCtrl.clear();
        _selectedDevice = null;
        _attachments.clear();
      });
      context.showAppToast(message: '反馈已提交，感谢您的宝贵建议', type: AppToastType.success);
      context.push(AppRoutes.feedbackList);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      context.showAppToast(message: ApiException.from(e).message, type: AppToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        title: Text(
          s.feedback,
          style: const TextStyle(color: Color(0xFF222222), fontSize: 18, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: () => context.push(AppRoutes.feedbackList),
            child: const Text(
              '我的反馈',
              style: TextStyle(color: _primaryPurple, fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
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
                // 1. 反馈类型选择
                Row(
                  children: FeedbackKind.values.map((k) {
                    final selected = _kind == k;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: k == FeedbackKind.general ? 12 : 0),
                        child: GestureDetector(
                          onTap: () => _onKindChanged(k),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            decoration: BoxDecoration(
                              color: selected ? _primaryPurple.withValues(alpha: 0.1) : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: selected ? _primaryPurple : const Color(0xFFE5E5E5),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  k == FeedbackKind.general ? Icons.chat_bubble_outline : Icons.devices_other_rounded,
                                  size: 18,
                                  color: selected ? _primaryPurple : Colors.grey,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  k.label,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                                    color: selected ? _primaryPurple : const Color(0xFF555555),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // 2. 关联设备（仅设备反馈时展示，选填）
                if (_kind == FeedbackKind.device) ...[
                  _buildCardGroup(
                    children: [
                      Consumer<DeviceProvider>(
                        builder: (context, deviceProvider, _) {
                          final label = _selectedDevice == null
                              ? '选填，选择相关设备'
                              : (_selectedDevice!.nickname.isNotEmpty
                                    ? _selectedDevice!.nickname
                                    : deviceProvider.resolveDisplayId(_selectedDevice!));
                          return ListTile(
                            title: const Text('关联设备', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 180),
                                  child: Text(
                                    label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: _selectedDevice != null ? const Color(0xFF333333) : Colors.grey,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey, size: 14),
                              ],
                            ),
                            onTap: () => _showDevicePicker(deviceProvider.devices),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // 3. 标题与正文
                _buildCardGroup(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: TextField(
                        controller: _titleCtrl,
                        maxLength: 60,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF333333)),
                        decoration: const InputDecoration(
                          hintText: '简要概括问题或建议（必填）',
                          hintStyle: TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.normal),
                          border: InputBorder.none,
                          counterText: '',
                        ),
                      ),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFF0EFF5)),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                      child: TextField(
                        controller: _bodyCtrl,
                        minLines: 4,
                        maxLines: 8,
                        maxLength: 500,
                        style: const TextStyle(fontSize: 14, color: Color(0xFF333333), height: 1.5),
                        decoration: const InputDecoration(
                          hintText: '请详细描述发生时间、现象或改进建议，以便我们更快定位处理（必填）',
                          hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                          border: InputBorder.none,
                          counterStyle: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 4. 图片上传（选填）
                _buildCardGroup(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                      child: Row(
                        children: [
                          Text(
                            '上传图片（选填）',
                            style: TextStyle(fontSize: 14, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                          ),
                          const Spacer(),
                          Text(
                            '${_attachments.length}/$_maxAttachments',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          ..._attachments.asMap().entries.map((entry) {
                            final index = entry.key;
                            final item = entry.value;
                            return Stack(
                              clipBehavior: Clip.none,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    item.url,
                                    width: 76,
                                    height: 76,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 76,
                                      height: 76,
                                      color: const Color(0xFFF0EFF5),
                                      child: const Icon(Icons.broken_image_outlined, color: Colors.grey),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: -6,
                                  right: -6,
                                  child: GestureDetector(
                                    onTap: () => setState(() => _attachments.removeAt(index)),
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
                          if (_attachments.length < _maxAttachments)
                            GestureDetector(
                              onTap: _isUploading ? null : () => _showImagePicker(s),
                              child: Container(
                                width: 76,
                                height: 76,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF9F9FC),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFE5E5E5), width: 1.5),
                                ),
                                child: _isUploading
                                    ? const Center(
                                        child: SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: _primaryPurple),
                                        ),
                                      )
                                    : const Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.add_photo_alternate_outlined, color: _primaryPurple, size: 26),
                                          SizedBox(height: 4),
                                          Text('添加图片', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                        ],
                                      ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // 5. 提交按钮
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryPurple,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      elevation: 0,
                    ),
                    onPressed: (_isSubmitting || _isUploading) ? null : _submit,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text(
                            '提交反馈',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
                const SizedBox(height: 24),

                // 6. 保留官方联系方式
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _primaryPurple.withValues(alpha: 0.12)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '其他联系渠道',
                        style: TextStyle(fontSize: 12, color: Color(0xFF888888), fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        '电子邮箱：${AppConstants.officialEmail}',
                        style: const TextStyle(fontSize: 13, color: Color(0xFF444444)),
                      ),
                      const SizedBox(height: 4),
                      SelectableText(
                        '官方网站：${AppConstants.officialWebsite}',
                        style: const TextStyle(fontSize: 13, color: Color(0xFF444444)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
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
}
