import 'package:flutter/material.dart';
import 'package:netra/core/loadstate/load_state.dart';

abstract class BaseViewModel extends ChangeNotifier {
  LoadState _state = LoadState.idle;
  String? _error;

  LoadState get state => _state;
  String? get error => _error;

  void setLoading() {
    _state = LoadState.loading;
    notifyListeners();
  }

  void setSuccess() {
    _state = LoadState.success;
    notifyListeners();
  }

  void setError(String message) {
    _state = LoadState.error;
    _error = message;
    notifyListeners();
  }
}
