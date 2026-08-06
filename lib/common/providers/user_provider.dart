import 'package:flutter/foundation.dart';
import 'package:fullxpet/common/models/user_dto.dart';

class UserProvider extends ChangeNotifier {
  UserDto? _currentUser;
  UserDto? get currentUser => _currentUser;

  void setUser(UserDto user) {
    _currentUser = user;
    notifyListeners();
  }

  void clearUser() {
    _currentUser = null;
    notifyListeners();
  }
}
