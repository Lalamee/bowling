import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

import '../../data/knowledge_base_repository.dart';
import '../../domain/kb_pdf.dart';

class PdfReaderScreen extends StatefulWidget {
  final KbPdf doc;

  const PdfReaderScreen({super.key, required this.doc});

  @override
  State<PdfReaderScreen> createState() => _PdfReaderScreenState();
}

class _PdfReaderScreenState extends State<PdfReaderScreen> {
  final KnowledgeBaseRepository _repository = KnowledgeBaseRepository();

  PdfControllerPinch? _controller;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDocument();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _loadDocument() async {
    try {
      final bytes = await _repository.fetchDocument(widget.doc.url);
      if (!mounted) return;
      final controller = PdfControllerPinch(
        document: PdfDocument.openData(bytes),
      );
      setState(() {
        _controller = controller;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.doc.title),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorState(message: _error!, onRetry: _retry)
              : PdfViewPinch(controller: _controller!),
    );
  }

  void _retry() {
    setState(() {
      _loading = true;
      _error = null;
    });
    _controller?.dispose();
    _controller = null;
    _loadDocument();
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(color: Colors.black54),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Повторить попытку'),
            ),
          ],
        ),
      ),
    );
  }
}
