class KbPdf {
  final int id;
  final String title;
  final int? clubId;
  final String? clubName;
  final String? description;
  final String? documentType;
  final String? fileName;
  final int? fileSize;
  final DateTime? uploadDate;
  final String downloadUrl;

  const KbPdf({
    required this.id,
    required this.title,
    required this.downloadUrl,
    this.clubId,
    this.clubName,
    this.description,
    this.documentType,
    this.fileName,
    this.fileSize,
    this.uploadDate,
  });

  factory KbPdf.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value is String && value.isNotEmpty) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    int? parseInt(dynamic value) => (value is num) ? value.toInt() : null;

    final id = parseInt(json['documentId']) ?? 0;
    final rawDownloadUrl = json['downloadUrl']?.toString() ?? '';

    return KbPdf(
      id: id,
      title: json['title']?.toString() ?? 'Документ',
      downloadUrl: rawDownloadUrl.isNotEmpty ? rawDownloadUrl : (id > 0 ? '/api/knowledge-base/documents/$id/content' : ''),
      clubId: parseInt(json['clubId']),
      clubName: json['clubName']?.toString(),
      description: json['description']?.toString(),
      documentType: json['documentType']?.toString(),
      fileName: json['fileName']?.toString(),
      fileSize: parseInt(json['fileSize']),
      uploadDate: parseDate(json['uploadDate']),
    );
  }
}
