class ResultEntity<T> {
  final String? requestId;
  final String message;
  final T? data;
  final int? code;

  ResultEntity({required this.requestId, required this.message, this.data, this.code});

  factory ResultEntity.success(T? data, {String msg = '成功', int? code = 200}) {
    return ResultEntity(requestId: null, message: msg, data: data, code: code);
  }

  factory ResultEntity.error(String msg, {int? code, String? requestId}) {
    return ResultEntity(requestId: requestId, message: msg, data: null, code: code);
  }
}
