import 'package:uuid/uuid.dart';

class UuidsTool {
  static String generateStandardUUID() {
    return const Uuid().v4();
  }
}
