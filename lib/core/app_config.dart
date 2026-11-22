/// قيم يضبطها المطوّر قبل النشر. اترك الحقول الفارغة كما هي
/// إلى أن يتوفر عنوان أو رابط حقيقي، ولا تضع بيانات وهمية.
class AppConfig {
  const AppConfig._();

  /// بريد الدعم الرسمي. اتركه فارغًا إلى أن يتوفر.
  static const String supportEmail = 'waleed.mohammed.gamal@gmail.com';

  /// نص يُعرض للمستخدم عندما لا يكون بريد الدعم مضافًا بعد.
  static const String supportEmailPlaceholder = 'waleed.mohammed.gamal@gmail.com';

  /// رابط صفحة التطبيق على Google Play.
  /// مثال بعد النشر: الرابط الكامل الذي تمنحه Play Console.
  static const String playStoreListingUrl = '';
}
