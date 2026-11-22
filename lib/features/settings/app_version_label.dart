import 'package:package_info_plus/package_info_plus.dart';

/// يقرأ إصدار التطبيق ورقم البناء من حزمة النظام المثبتة.
Future<String> loadAppVersionLabel() async {
  try {
    final info = await PackageInfo.fromPlatform();
    final version = info.version.trim();
    final build = info.buildNumber.trim();
    if (version.isEmpty && build.isEmpty) return 'غير متاح';
    if (build.isEmpty) return version;
    if (version.isEmpty) return build;
    return '$version ($build)';
  } catch (_) {
    return 'غير متاح';
  }
}
