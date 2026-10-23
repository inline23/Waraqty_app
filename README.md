<img width="1536" height="1024" alt="Waraqty Arabic Exam App Showcase" src="https://github.com/user-attachments/assets/56227528-5b35-4494-baae-e5039090c071" />

# Waraqty | ورقتي

A Flutter application that helps teachers in Egypt create, save, edit, and export exams as print-ready PDF files.

ورقتي هو تطبيق بيساعد المدرسين في مصر على إنشاء الامتحانات وتنظيمها وحفظها وتعديلها، وتجهيزها في ملف PDF جاهز للطباعة.

## ✨ Features

- Create exams and manage exam details.
- Add questions and choose question types.
- Save exams locally and access them later.
- Edit previously saved exams.
- Export exams to PDF in A4 format.
- Support Arabic text and right-to-left (RTL) layout.

## 🛠️ Tech Stack

- Flutter & Dart
- Cubit for state management
- SharedPreferences for local storage
- pdf package for PDF generation

## 🗺️ Roadmap

- [ ] Question Bank — reuse questions from previous exams.
- [ ] Online Exams — create online exam rooms.
- [ ] Student Access — join exams using a room code.
- [ ] Timed exams and student submissions.

> Roadmap features are planned for future releases and are not available in the current version.

## 📲 Download Android Build

[Download Waraqty APK](https://drive.google.com/file/d/1al__jwN9M2sb7ZDdeDWdgDnBvX4aJz8O/view?usp=drive_link)

## 🚀 Getting Started

### Prerequisites

- Flutter SDK
- Dart SDK
- Android Studio or VS Code

### Installation

1. Clone the repository:

   ```bash
   git clone https://github.com/inline23/Waraqty_app.git
   ```

2. Open the project:

   ```bash
   cd Waraqty_app
   ```

3. Install dependencies:

   ```bash
   flutter pub get
   ```

4. Run the application:

   ```bash
   flutter run
   ```

## 💾 Data Storage

The current version stores exam data locally on the device using SharedPreferences.

The core exam-creation workflow does not currently require user accounts or a remote backend.

## 💬 Feedback

Feedback and feature suggestions are welcome!

If you are a teacher, share the challenges you face when preparing exams and the features you would like to see in Waraqty.

## 👨‍💻 Developer

**Waraqty | ورقتي**

GitHub: [inline23/Waraqty_app](https://github.com/inline23/Waraqty_app)

---

Built with Flutter 💜
