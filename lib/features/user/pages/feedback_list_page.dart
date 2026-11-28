import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:fullxpet/common/theme/app_theme.dart';
import 'package:fullxpet/common/widgets/responsive_layout.dart';
import 'package:fullxpet/core/network/api_exception.dart';
import 'package:fullxpet/locator.dart';
import 'package:fullxpet/routes/app_router.dart';
import '../models/feedback_dto.dart';
import '../repositories/feedback_repository.dart';

class FeedbackListPage extends StatefulWidget {
  const FeedbackListPage({super.key});

  @override
  State<FeedbackListPage> createState() => _FeedbackListPageState();
}

class _FeedbackListPageState extends State<FeedbackListPage> {
  static const int _pageSize = 20;

  final FeedbackRepository _repo = locator<FeedbackRepository>();
  final List<FeedbackItemDto> _items = [];

  int _currentPage = 0;
  int _total = 0;
  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  String _errorMsg = '';

  bool get _hasMore => _items.length < _total;

  @override
  void initState() {
    super.initState();
    _loadPage(page: 1, reset: true);
  }

  Future<void> _loadPage({required int page, bool reset = false}) async {
    if (reset) {
      setState(() {
        _isInitialLoading = true;
        _errorMsg = '';
      });
    } else {
      if (_isLoadingMore || !_hasMore) return;
      setState(() => _isLoadingMore = true);
    }

    try {
      final result = await _repo.getMyFeedbacks(page: page, size: _pageSize);
      if (!mounted) return;
      setState(() {
        if (reset) _items.clear();
        _items.addAll(result.items);
        _currentPage = result.page;
        _total = result.total;
        _isInitialLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isInitialLoading = false;
        _isLoadingMore = false;
        _errorMsg = ApiException.from(e).message;
      });
    }
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
          '我的反馈',
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
    if (_isInitialLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryPurple));
    }
    if (_errorMsg.isNotEmpty && _items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_errorMsg, style: const TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => _loadPage(page: 1, reset: true),
              child: const Text('重试', style: TextStyle(color: AppTheme.primaryPurple)),
            ),
          ],
        ),
      );
    }
    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            const Text('暂无反馈记录', style: TextStyle(color: Colors.grey, fontSize: 14)),
          ],
        ),
      );
    }

    return ListView.separated(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      itemCount: _items.length + (_hasMore ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index == _items.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Center(
              child: _isLoadingMore
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryPurple),
                    )
                  : TextButton(
                      onPressed: () => _loadPage(page: _currentPage + 1),
                      child: const Text('加载更多', style: TextStyle(color: AppTheme.primaryPurple)),
                    ),
            ),
          );
        }
        return _buildItemCard(_items[index]);
      },
    );
  }

  Widget _buildItemCard(FeedbackItemDto item) {
    final status = item.feedbackStatus;
    final statusColor = _statusColor(status);

    return GestureDetector(
      onTap: () => context.push(AppRoutes.feedbackDetailPath(item.feedbackId)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
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
                    style: const TextStyle(fontSize: 11, color: AppTheme.primaryPurple, fontWeight: FontWeight.w500),
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
            const SizedBox(height: 10),
            Text(
              item.title.isNotEmpty ? item.title : '无标题反馈',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
            ),
            if (item.body.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                item.body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, color: Color(0xFF666666), height: 1.45),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Text(item.createdAtDisplay, style: const TextStyle(fontSize: 12, color: Color(0xFF999999))),
                const Spacer(),
                if (item.hasReply)
                  const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.mark_chat_read_outlined, size: 14, color: Color(0xFF2E9E6B)),
                      SizedBox(width: 4),
                      Text('已回复', style: TextStyle(fontSize: 12, color: Color(0xFF2E9E6B))),
                    ],
                  ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
