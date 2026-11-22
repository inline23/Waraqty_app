enum OnboardingVisual { exams, questionBank, printReady }

class OnboardingPageData {
  const OnboardingPageData({
    required this.title,
    required this.description,
    required this.visual,
  });

  final String title;
  final String description;
  final OnboardingVisual visual;
}
