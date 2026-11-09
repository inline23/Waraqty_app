import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:printing/printing.dart';

import '../models/exam_model.dart';
import '../models/exam_print_settings.dart';
import '../services/exam_pdf_service.dart';

const _purple = Color(0xFF431599);
const _background = Color(0xFFFAF9FF);
const _lavender = Color(0xFFF1ECFA);
const _border = Color(0xFFE5DDF3);

/// شاشة اختيار قالب PDF وضبط إعدادات الطباعة.
class PdfSettingsScreen extends StatefulWidget {
  final ExamModel exam;
  final ExamPrintSettings initialSettings;

  const PdfSettingsScreen({
    super.key,
    required this.exam,
    required this.initialSettings,
  });

  @override
  State<PdfSettingsScreen> createState() => _PdfSettingsScreenState();
}

class _PdfSettingsScreenState extends State<PdfSettingsScreen> {
  late ExamPrintSettings _settings;
  final _schoolNameCtrl = TextEditingController();
  final _headerTextCtrl = TextEditingController();
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _settings = widget.initialSettings;
    _schoolNameCtrl.text = _settings.schoolName ?? '';
    _headerTextCtrl.text = _settings.headerText ?? '';
  }

  @override
  void dispose() {
    _schoolNameCtrl.dispose();
    _headerTextCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 600,
      maxHeight: 300,
      imageQuality: 85,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() {
      _settings = _settings.copyWith(logoImageBytes: bytes);
    });
  }

  void _removeLogo() {
    setState(() {
      _settings = _settings.copyWith(clearLogo: true);
    });
  }

  Future<void> _previewPdf() async {
    final settings = _currentSettings();
    setState(() => _isGenerating = true);
    try {
      await Printing.layoutPdf(
        name: ExamPdfService.fileName(widget.exam),
        onLayout: (_) => ExamPdfService.build(widget.exam, settings),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تعذر إنشاء المعاينة: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _exportPdf() async {
    final settings = _currentSettings();
    setState(() => _isGenerating = true);
    try {
      final bytes = await ExamPdfService.build(widget.exam, settings);
      await Printing.sharePdf(
        bytes: bytes,
        filename: ExamPdfService.fileName(widget.exam),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تعذر تصدير PDF: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  ExamPrintSettings _currentSettings() => _settings.copyWith(
    schoolName: _schoolNameCtrl.text.trim().isEmpty
        ? null
        : _schoolNameCtrl.text.trim(),
    headerText: _headerTextCtrl.text.trim().isEmpty
        ? null
        : _headerTextCtrl.text.trim(),
  );

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _background,
        appBar: AppBar(
          backgroundColor: _purple,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'تخصيص ورقة الامتحان',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
                children: [
                  // ── اختيار القالب ────────────────────────────────────
                  _sectionTitle('اختر قالب الورقة'),
                  const SizedBox(height: 12),
                  _buildTemplateSelector(),
                  const SizedBox(height: 24),

                  // ── بيانات المؤسسة ───────────────────────────────────
                  _sectionTitle('بيانات المؤسسة التعليمية'),
                  const SizedBox(height: 12),
                  _buildSchoolFields(),
                  const SizedBox(height: 24),

                  // ── الشعار ───────────────────────────────────────────
                  _sectionTitle('شعار المدرسة / المركز'),
                  const SizedBox(height: 12),
                  _buildLogoSection(),
                  const SizedBox(height: 24),

                  // ── لون الرأس ────────────────────────────────────────
                  _sectionTitle('لون رأس الورقة'),
                  const SizedBox(height: 12),
                  _buildColorSelector(),
                  const SizedBox(height: 24),

                  // ── عناصر الورقة ─────────────────────────────────────
                  _sectionTitle('عناصر الورقة'),
                  const SizedBox(height: 12),
                  _buildToggles(),
                  const SizedBox(height: 20),
                ],
              ),
            ),

            // ── أزرار التنفيذ ─────────────────────────────────────────
            _buildBottomActions(),
          ],
        ),
      ),
    );
  }

  // ─── Template Selector ─────────────────────────────────────────────────────

  Widget _buildTemplateSelector() {
    return Row(
      children: ExamTemplate.values.map((template) {
        final selected = _settings.template == template;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() {
              _settings = _settings.copyWith(template: template);
            }),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
              decoration: BoxDecoration(
                color: selected ? _purple : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected ? _purple : _border,
                  width: selected ? 2 : 1,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: _purple.withOpacity(0.18),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: Column(
                children: [
                  Icon(
                    template.icon,
                    color: selected ? Colors.white : _purple,
                    size: 26,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    template.arabicName,
                    style: TextStyle(
                      color: selected ? Colors.white : _purple,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    template.arabicDescription,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: selected
                          ? Colors.white.withOpacity(0.8)
                          : Colors.black54,
                      fontSize: 10,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─── School Fields ─────────────────────────────────────────────────────────

  Widget _buildSchoolFields() {
    return Column(
      children: [
        _buildTextField(
          controller: _schoolNameCtrl,
          hint: 'اسم المدرسة أو المركز التعليمي',
          icon: Icons.school_outlined,
        ),
        const SizedBox(height: 10),
        _buildTextField(
          controller: _headerTextCtrl,
          hint: 'نص إضافي في الرأس (اختياري)',
          icon: Icons.text_fields_outlined,
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: _purple, size: 20),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: _purple, width: 1.5),
        ),
      ),
    );
  }

  // ─── Logo Section ──────────────────────────────────────────────────────────

  Widget _buildLogoSection() {
    final hasLogo = _settings.logoImageBytes != null;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          if (hasLogo) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.memory(
                _settings.logoImageBytes!,
                height: 100,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('تغيير'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _purple,
                    side: const BorderSide(color: _purple),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: _removeLogo,
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: const Text('حذف'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            const Icon(Icons.image_outlined, size: 42, color: Color(0xFFBBABD6)),
            const SizedBox(height: 8),
            const Text(
              'أضف شعار المدرسة أو المركز',
              style: TextStyle(color: Colors.black54, fontSize: 13),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.upload_outlined, size: 18),
              label: const Text('رفع صورة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _lavender,
                foregroundColor: _purple,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Color Selector ────────────────────────────────────────────────────────

  static const _colors = [
    Color(0xFF431599),
    Color(0xFF1A73E8),
    Color(0xFF188038),
    Color(0xFFB5181B),
    Color(0xFFE37400),
    Color(0xFF37474F),
    Color(0xFF6A1B9A),
    Color(0xFF00695C),
  ];

  Widget _buildColorSelector() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _colors.map((color) {
        final selected = _settings.headerColor.value == color.value;
        return GestureDetector(
          onTap: () => setState(() {
            _settings = _settings.copyWith(headerColor: color);
          }),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? Colors.white : Colors.transparent,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(selected ? 0.6 : 0.2),
                  blurRadius: selected ? 8 : 3,
                ),
              ],
            ),
            child: selected
                ? const Icon(Icons.check, color: Colors.white, size: 18)
                : null,
          ),
        );
      }).toList(),
    );
  }

  // ─── Toggles ───────────────────────────────────────────────────────────────

  Widget _buildToggles() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          _toggle(
            title: 'بسم الله الرحمن الرحيم',
            icon: Icons.mosque_outlined,
            value: _settings.showBazmala,
            onChanged: (v) =>
                setState(() => _settings = _settings.copyWith(showBazmala: v)),
          ),
          _divider(),
          _toggle(
            title: 'اسم المدرس',
            icon: Icons.person_outline,
            value: _settings.showTeacherName,
            onChanged: (v) => setState(
                () => _settings = _settings.copyWith(showTeacherName: v)),
          ),
          _divider(),
          _toggle(
            title: 'المادة والصف',
            icon: Icons.book_outlined,
            value: _settings.showSubjectGrade,
            onChanged: (v) => setState(
                () => _settings = _settings.copyWith(showSubjectGrade: v)),
          ),
          _divider(),
          _toggle(
            title: 'الزمن والدرجة النهائية',
            icon: Icons.timer_outlined,
            value: _settings.showDurationMarks,
            onChanged: (v) => setState(
                () => _settings = _settings.copyWith(showDurationMarks: v)),
          ),
          _divider(),
          _toggle(
            title: 'بيانات الطالب',
            icon: Icons.assignment_ind_outlined,
            value: _settings.showStudentInfo,
            onChanged: (v) => setState(
                () => _settings = _settings.copyWith(showStudentInfo: v)),
          ),
          _divider(),
          _toggle(
            title: 'الزخارف والفواصل',
            icon: Icons.border_all_outlined,
            value: _settings.showDecorations,
            onChanged: (v) => setState(
                () => _settings = _settings.copyWith(showDecorations: v)),
          ),
        ],
      ),
    );
  }

  Widget _toggle({
    required String title,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: _purple),
          const SizedBox(width: 10),
          Expanded(
            child: Text(title, style: const TextStyle(fontSize: 14)),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: _purple,
          ),
        ],
      ),
    );
  }

  Widget _divider() => const Divider(height: 1, color: _border);

  // ─── Bottom Actions ────────────────────────────────────────────────────────

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: _purple.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: _isGenerating ? null : _exportPdf,
                icon: _isGenerating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.picture_as_pdf_outlined),
                label: Text(
                  _isGenerating ? 'جارٍ الإنشاء...' : 'تصدير / مشاركة PDF',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: _purple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _isGenerating ? null : _previewPdf,
                icon: const Icon(Icons.preview_outlined, size: 19),
                label: const Text(
                  'معاينة PDF قبل التصدير',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _purple,
                  side: const BorderSide(color: Color(0xFFBBA7E4)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: Color(0xFF292333),
      ),
    );
  }
}
