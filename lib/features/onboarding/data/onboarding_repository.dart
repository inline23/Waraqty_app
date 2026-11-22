import 'package:shared_preferences/shared_preferences.dart';

/// يحفظ اكتمال شاشات البداية حتى لا تظهر إلا في أول تشغيل.
class OnboardingRepository {
  static const String completedKey = 'onboarding_completed';

  Future<bool> isCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(completedKey) ?? false;
  }

  Future<void> markCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = await prefs.setBool(completedKey, true);
    if (!saved) {
      throw Exception('تعذر حفظ حالة البداية');
    }
  }
}
