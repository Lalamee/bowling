import 'package:flutter/material.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/utils/bottom_nav.dart';
import '../../../../core/utils/net_ui.dart';
import '../../../../shared/widgets/nav/app_bottom_nav.dart';
import '../../../../shared/widgets/tiles/kb_list_tile.dart';
import '../../data/knowledge_base_repository.dart';
import '../../domain/kb_pdf.dart';
import 'pdf_reader_screen.dart';

class KnowledgeBaseScreen extends StatefulWidget {
  const KnowledgeBaseScreen({Key? key}) : super(key: key);

  @override
  State<KnowledgeBaseScreen> createState() => _KnowledgeBaseScreenState();
}

class _KnowledgeBaseScreenState extends State<KnowledgeBaseScreen> {
  final KnowledgeBaseRepository _repository = KnowledgeBaseRepository();

  bool _loadingDocuments = true;
  bool _documentsError = false;
  List<KbPdf> _documents = const [];

  @override
  void initState() {
    super.initState();
    _loadKnowledgeBase();
  }

  Future<void> _loadKnowledgeBase() async {
    setState(() {
      _loadingDocuments = true;
      _documentsError = false;
    });
    try {
      final docs = await _repository.load();
      if (!mounted) return;
      setState(() {
        _documents = docs;
        _loadingDocuments = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _documentsError = true;
        _loadingDocuments = false;
      });
      showApiError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F6F9),
        elevation: 0,
        title: const Text(
          'База знаний',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textDark),
        ),
        actions: [
          IconButton(
            onPressed: _loadKnowledgeBase,
            icon: const Icon(Icons.sync),
            color: AppColors.primary,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE9E9E9)),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text(
              'Инструкции',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark),
            ),
          ),
          const SizedBox(height: 10),
          if (_loadingDocuments)
            const Padding(
              padding: EdgeInsets.only(top: 32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_documentsError)
            Padding(
              padding: const EdgeInsets.only(top: 32),
              child: Column(
                children: [
                  const Icon(Icons.cloud_off, size: 64, color: AppColors.darkGray),
                  const SizedBox(height: 12),
                  const Text(
                    'Не удалось загрузить документы',
                    style: TextStyle(color: AppColors.darkGray),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _loadKnowledgeBase,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Повторить попытку'),
                  ),
                ],
              ),
            )
          else if (_documents.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 32),
              child: Center(
                child: Text(
                  'Нет доступных документов',
                  style: TextStyle(color: AppColors.darkGray),
                ),
              ),
            )
          else
            Column(
              children: List.generate(_documents.length, (i) {
                final doc = _documents[i];
                return Padding(
                  padding: EdgeInsets.only(bottom: i == _documents.length - 1 ? 0 : 10),
                  child: KbListTile(
                    title: doc.title,
                    accent: i == 0,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => PdfReaderScreen(doc: doc)),
                      );
                    },
                  ),
                );
              }),
            ),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 3,
        onTap: (i) => BottomNavDirect.go(context, 3, i),
      ),
    );
  }
}
