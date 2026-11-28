/// 反馈类型枚举
enum FeedbackKind {
  general('general', '普通反馈'),
  device('device', '设备反馈');

  final String value;
  final String label;
  const FeedbackKind(this.value, this.label);

  static FeedbackKind fromValue(String? val) {
    return FeedbackKind.values.firstWhere((e) => e.value == val?.toLowerCase(), orElse: () => FeedbackKind.general);
  }
}

/// 反馈处理状态枚举
enum FeedbackStatus {
  pending('pending', '待处理'),
  processing('processing', '处理中'),
  resolved('resolved', '已解决'),
  closed('closed', '已关闭');

  final String value;
  final String label;
  const FeedbackStatus(this.value, this.label);

  static FeedbackStatus fromValue(String? val) {
    final normalized = val?.toLowerCase() ?? '';
    return FeedbackStatus.values.firstWhere((e) => e.value == normalized, orElse: () => FeedbackStatus.pending);
  }
}

/// 反馈附件图片 DTO
class FeedbackAttachmentDto {
  final String key;
  final String url;
  final String mime;
  final int size;

  const FeedbackAttachmentDto({required this.key, required this.url, this.mime = '', this.size = 0});

  factory FeedbackAttachmentDto.fromJson(Map<String, dynamic> json) {
    return FeedbackAttachmentDto(
      key: json['key']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
      mime: json['mime']?.toString() ?? '',
      size: int.tryParse(json['size']?.toString() ?? '') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'key': key, 'url': url, 'mime': mime, 'size': size};
  }
}

/// 单条反馈记录 DTO（用于列表与详情）
class FeedbackItemDto {
  final String feedbackId;
  final String kind;
  final String title;
  final String body;
  final String deviceId;
  final String productId;
  final String homeId;
  final String status;
  final String priority;
  final String reply;
  final String repliedAt;
  final String createdAt;
  final String updatedAt;
  final List<FeedbackAttachmentDto> attachments;

  const FeedbackItemDto({
    required this.feedbackId,
    this.kind = 'general',
    this.title = '',
    this.body = '',
    this.deviceId = '',
    this.productId = '',
    this.homeId = '',
    this.status = 'pending',
    this.priority = 'normal',
    this.reply = '',
    this.repliedAt = '',
    this.createdAt = '',
    this.updatedAt = '',
    this.attachments = const [],
  });

  FeedbackKind get feedbackKind => FeedbackKind.fromValue(kind);
  FeedbackStatus get feedbackStatus => FeedbackStatus.fromValue(status);
  bool get hasReply => reply.trim().isNotEmpty;

  String get createdAtDisplay => _formatIsoTime(createdAt);
  String get repliedAtDisplay => _formatIsoTime(repliedAt);

  static String _formatIsoTime(String raw) {
    if (raw.isEmpty) return '';
    final dt = DateTime.tryParse(raw)?.toLocal();
    if (dt == null) return raw;
    String two(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}';
  }

  factory FeedbackItemDto.fromJson(Map<String, dynamic> json) {
    final rawAttachments = json['attachments'] as List?;
    final parsedAttachments = <FeedbackAttachmentDto>[
      if (rawAttachments != null)
        for (final e in rawAttachments)
          if (e is Map<String, dynamic>)
            if ((e['url']?.toString().isNotEmpty ?? false) || (e['key']?.toString().isNotEmpty ?? false))
              FeedbackAttachmentDto.fromJson(e),
    ];

    return FeedbackItemDto(
      feedbackId: json['feedbackId']?.toString() ?? '',
      kind: json['kind']?.toString() ?? 'general',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      deviceId: json['deviceId']?.toString() ?? '',
      productId: json['productId']?.toString() ?? '',
      homeId: json['homeId']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      priority: json['priority']?.toString() ?? 'normal',
      reply: json['reply']?.toString() ?? '',
      repliedAt: json['repliedAt']?.toString() ?? '',
      createdAt: json['createdAt']?.toString() ?? '',
      updatedAt: json['updatedAt']?.toString() ?? '',
      attachments: parsedAttachments,
    );
  }
}

/// 我的反馈分页结果 DTO
class FeedbackPageResult {
  final List<FeedbackItemDto> items;
  final int page;
  final int size;
  final int total;

  const FeedbackPageResult({required this.items, required this.page, required this.size, required this.total});

  factory FeedbackPageResult.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List?;
    return FeedbackPageResult(
      items: [
        if (rawItems != null)
          for (final e in rawItems)
            if (e is Map<String, dynamic>) FeedbackItemDto.fromJson(e),
      ],
      page: int.tryParse(json['page']?.toString() ?? '') ?? 1,
      size: int.tryParse(json['size']?.toString() ?? '') ?? 20,
      total: int.tryParse(json['total']?.toString() ?? '') ?? 0,
    );
  }
}
