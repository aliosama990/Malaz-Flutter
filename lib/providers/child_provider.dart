import 'package:flutter/material.dart';
import 'package:malaz_app/models/child_mode.dart';

class ChildProvider with ChangeNotifier {
  List<ChildModel> _children = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ChildModel> get children => _children;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get childrenCount => _children.length;

  Future<bool> addChild({
    required String name,
    required String birthDate,
    required String gender,
    required String deviceId,
    required String userId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await Future.delayed(const Duration(seconds: 2));

      final newChild = ChildModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        birthDate: birthDate,
        gender: gender,
        deviceId: deviceId,
        userId: userId,
      );

      _children.add(newChild);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'حدث خطأ أثناء إضافة الطفل';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ✅ تحديث بيانات طفل موجود
  void updateChild(ChildModel updatedChild) {
    final index = _children.indexWhere((c) => c.id == updatedChild.id);
    if (index != -1) {
      _children[index] = updatedChild;
    } else {
      _children.add(updatedChild);
    }
    notifyListeners();
  }

  // جلب طفل بـ ID معين
  ChildModel? getChildById(String childId) {
    try {
      return _children.firstWhere((child) => child.id == childId);
    } catch (e) {
      return null;
    }
  }

  // حذف طفل
  void removeChild(String childId) {
    _children.removeWhere((child) => child.id == childId);
    notifyListeners();
  }

  // مسح كل الأطفال
  void clearChildren() {
    _children.clear();
    notifyListeners();
  }
}
