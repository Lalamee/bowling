import '../domain/kb_pdf.dart';

class KbRepository {
  static Future<List<KbPdf>> load() async {
    return const [
      KbPdf(
        title: 'Инструкция по монтажу террасной доски',
        assetPath: 'assets/pdfs/instruction_terrace_deck.pdf',
      ),
      KbPdf(
        title: 'Схема скрытого крепления заглушки',
        assetPath: 'assets/pdfs/hidden_cap_scheme.pdf',
      ),
    ];
  }
}
