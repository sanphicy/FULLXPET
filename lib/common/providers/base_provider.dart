import 'package:flutter/material.dart';
import 'package:fullxpet/common/widgets/app_dialogs.dart';
import 'package:fullxpet/core/navigation/nav_service.dart';

abstract class BaseProvider extends ChangeNotifier {
  bool _isLoading = false;
  String _errorMsg = '';
  bool _isDisposed = false;

  bool get isLoading => _isLoading;
  bool get hasError => _errorMsg.isNotEmpty;
  String get errorMsg => _errorMsg;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  void setLoading(bool value) {
    if (_isLoading == value) return;
    _isLoading = value;
    notifyListeners();
  }

  void setError(String message) {
    _errorMsg = message;
    _isLoading = false;
    notifyListeners();

    final context = NavService.rootNavigatorKey.currentContext;
    if (context != null) {
      context.showAppToast(message: message, type: AppToastType.error);
    }
  }

  void clearError() {
    if (_errorMsg.isEmpty) return;
    _errorMsg = '';
    notifyListeners();
  }
}
