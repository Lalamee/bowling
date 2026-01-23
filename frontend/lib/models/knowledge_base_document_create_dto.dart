class KnowledgeBaseDocumentCreateDto {
  final int clubId;
  final String title;
  final String? description;
  final String? documentType;
  final String? manufacturer;
  final String? equipmentModel;
  final String? language;
  final String? accessLevel;
  final String? fileName;
  final String fileBase64;

  KnowledgeBaseDocumentCreateDto({
    required this.clubId,
    required this.title,
    this.description,
    this.documentType,
    this.manufacturer,
    this.equipmentModel,
    this.language,
    this.accessLevel,
    this.fileName,
    required this.fileBase64,
  });

  Map<String, dynamic> toJson() {
    return {
      'clubId': clubId,
      'title': title,
      'description': description,
      'documentType': documentType,
      'manufacturer': manufacturer,
      'equipmentModel': equipmentModel,
      'language': language,
      'accessLevel': accessLevel,
      'fileName': fileName,
      'fileBase64': fileBase64,
    };
  }
}
