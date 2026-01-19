class SupportAppealRequestDto {
  final String? subject;
  final String message;

  const SupportAppealRequestDto({
    this.subject,
    required this.message,
  });

  Map<String, dynamic> toJson() => {
        if (subject != null && subject!.trim().isNotEmpty) 'subject': subject?.trim(),
        'message': message.trim(),
      };
}
