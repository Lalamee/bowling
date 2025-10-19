class StandardResponseDto {
  final String message;
  final String status;

  StandardResponseDto({
    required this.message,
    required this.status,
  });

  factory StandardResponseDto.fromJson(Map<String, dynamic> json) {
    return StandardResponseDto(
      message: json['message'] as String,
      status: json['status'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'message': message,
        'status': status,
      };

  bool get isSuccess => status.toLowerCase() == 'success';
  bool get isError => status.toLowerCase() == 'error';
}
