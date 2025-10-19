class KbPdf {
  final String title;
  final String url;
  final int? clubId;
  final int? serviceId;

  const KbPdf({
    required this.title,
    required this.url,
    this.clubId,
    this.serviceId,
  });
}
