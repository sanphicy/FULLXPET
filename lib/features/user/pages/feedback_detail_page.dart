import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:fullxpet/common/theme/app_theme.dart';
import 'package:fullxpet/common/widgets/responsive_layout.dart';
import 'package:fullxpet/core/network/api_exception.dart';
import 'package:fullxpet/locator.dart';
import '../models/feedback_dto.dart';
import '../repositories/feedback_repository.dart';

class FeedbackDetailPage extends StatefulWidget {
  final String feedbackId;

  const FeedbackDetailPage({super.key, required this.feedbackId});

  @override
  State<FeedbackDetailPage> createState() => _FeedbackDetailPageState();
}

class _FeedbackDetailPageState extends State<FeedbackDetailPage> {
  final FeedbackRepository _repo = locator<FeedbackRepository>();

  FeedbackItemDto? _detail;
  bool _isLoading = true;
  String _errorMsg = '';

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _isLoading = true;
      _errorMsg = '';
    });
    try {
      final res = await _repo.getFeedbackDetail(widget.feedbackId);
      if (!mounted) return;
      setState(() {
        _detail = res;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMsg = ApiException.from(e).message;
      });
    }
  }

  void _previewImage(String url) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            InteractiveViewer(
              child: Center(
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined, color: Colors.white, size: 48),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(FeedbackStatus status) {
    switch (status) {
      case FeedbackStatus.resolved:
        return const Color(0xFF2E9E6B);
      case FeedbackStatus.processing:
        return AppTheme.primaryPurple;
      case FeedbackStatus.closed:
        return Colors.grey;
      case FeedbackStatus.pending:
        return const Color(0xFFE68A2E);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          '反馈详情',
          style: TextStyle(color: Color(0xFF222222), fontSize: 18, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(child: ResponsiveFormContainer(maxWidth: 600, child: _buildBody())),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryPurple));
    }
    if (_errorMsg.isNotEmpty || _detail == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_errorMsg.isNotEmpty ? _errorMsg : '未找到该反馈记录', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _loadDetail,
              child: const Text('重试', style: TextStyle(color: AppTheme.primaryPurple)),
            ),
          ],
        ),
      );
    }

    final item = _detail!;
    final status = item.feedbackStatus;
    final statusColor = _statusColor(status);

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.025), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryPurple.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.feedbackKind.label,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.primaryPurple,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        status.label,
                        style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  item.title.isNotEmpty ? item.title : '无标题反馈',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF222222)),
                ),
                const SizedBox(height: 6),
                Text('提交时间：${item.createdAtDisplay}', style: const TextStyle(fontSize: 12, color: Color(0xFF999999))),
                if (item.deviceId.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('关联设备：${item.deviceId}', style: const TextStyle(fontSize: 12, color: Color(0xFF999999))),
                ],
                const Divider(height: 24, color: Color(0xFFF0EFF5)),
                Text(item.body, style: const TextStyle(fontSize: 14, color: Color(0xFF444444), height: 1.6)),
                if (item.attachments.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: item.attachments.map((img) {
                      return GestureDetector(
                        onTap: img.url.isNotEmpty ? () => _previewImage(img.url) : null,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            img.url,
                            width: 84,
                            height: 84,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 84,
                              height: 84,
                              color: const Color(0xFFF0EFF5),
                              child: const Icon(Icons.broken_image_outlined, color: Colors.grey),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.025), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.support_agent_rounded, size: 18, color: AppTheme.primaryPurple),
                    const SizedBox(width: 6),
                    const Text(
                      '处理回复',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
                    ),
                    const Spacer(),
                    if (item.repliedAtDisplay.isNotEmpty)
                      Text(item.repliedAtDisplay, style: const TextStyle(fontSize: 12, color: Color(0xFF999999))),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  item.hasReply ? item.reply : '我们已收到您的反馈，工作人员将尽快处理并回复。',
                  style: TextStyle(
                    fontSize: 14,
                    color: item.hasReply ? const Color(0xFF333333) : Colors.grey,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
