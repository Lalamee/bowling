import 'package:flutter/material.dart';
import '../../../../../core/theme/colors.dart';
import '../../../../../core/theme/typography_extension.dart';
import '../../domain/kb_pdf.dart';

class PdfReaderScreen extends StatelessWidget {
  final String? assetPath;
  final String? title;
  final KbPdf? doc;

  const PdfReaderScreen({super.key, this.assetPath, this.title, this.doc});

  @override
  Widget build(BuildContext context) {
    final t = context.typo;
    final path = assetPath ?? doc?.assetPath ?? 'assets/pdfs/sample.pdf';
    final ttl = title ?? doc?.title ?? 'Документ';

    return Scaffold(
      appBar: AppBar(
        title: Text(ttl, style: t.sectionTitle),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.picture_as_pdf, size: 80, color: AppColors.primary),
            const SizedBox(height: 16),
            Text(path, style: t.formHint),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Здесь будет просмотр PDF из ассетов. Если используешь виджет просмотрщика, вставь его вместо этого блока, используя path.',
                textAlign: TextAlign.center,
                style: t.onboardingSubtitle.copyWith(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
