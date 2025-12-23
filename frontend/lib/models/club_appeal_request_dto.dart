class ClubAppealRequestDto {
  final int? clubId;
  final String type;
  final String message;
  final int? requestId;

  const ClubAppealRequestDto({
    this.clubId,
    required this.type,
    required this.message,
    this.requestId,
  });

  Map<String, dynamic> toJson() => {
        'clubId': clubId,
        'type': type,
        'message': message,
        'requestId': requestId,
      };
}
