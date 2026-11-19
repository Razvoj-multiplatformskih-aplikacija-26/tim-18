import 'json.dart';

/// An error as it travels: a code and the data of the rule. No message text.
final class ApiErrorDto {
  const ApiErrorDto({required this.code, this.data = const {}});

  /// Tolerant on purpose: whatever the server sends, the client gets an
  /// [ApiErrorDto] and can fall back to a generic message.
  factory ApiErrorDto.fromJson(Json json) {
    final code = json['code'];
    final data = json['data'];
    return ApiErrorDto(code: code is String ? code : 'unknown', data: data is Map<String, Object?> ? data : const {});
  }

  final String code;
  final Json data;

  int? intData(String key) {
    final value = data[key];
    return value is int ? value : null;
  }

  String? stringData(String key) {
    final value = data[key];
    return value is String ? value : null;
  }

  Json toJson() => {'code': code, 'data': data};

  @override
  String toString() => 'ApiErrorDto($code, $data)';
}
