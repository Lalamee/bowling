class PartRequestDto {
  final int clubId;
  final int? laneNumber;
  final int mechanicId;
  final String? managerNotes;
  final List<RequestedPartDto> requestedParts;

  PartRequestDto({
    required this.clubId,
    this.laneNumber,
    required this.mechanicId,
    this.managerNotes,
    required this.requestedParts,
  });

  Map<String, dynamic> toJson() => {
        'clubId': clubId,
        'laneNumber': laneNumber,
        'mechanicId': mechanicId,
        'managerNotes': managerNotes,
        'requestedParts': requestedParts.map((e) => e.toJson()).toList(),
      };

  factory PartRequestDto.fromJson(Map<String, dynamic> json) {
    return PartRequestDto(
      clubId: (json['clubId'] as num).toInt(),
      laneNumber: (json['laneNumber'] as num?)?.toInt(),
      mechanicId: (json['mechanicId'] as num).toInt(),
      managerNotes: json['managerNotes'] as String?,
      requestedParts: (json['requestedParts'] as List<dynamic>)
          .map((e) => RequestedPartDto.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}

class RequestedPartDto {
  final String? catalogNumber;
  final String partName;
  final int quantity;

  RequestedPartDto({
    this.catalogNumber,
    required this.partName,
    required this.quantity,
  });

  Map<String, dynamic> toJson() => {
        'catalogNumber': catalogNumber,
        'partName': partName,
        'quantity': quantity,
      };

  factory RequestedPartDto.fromJson(Map<String, dynamic> json) {
    return RequestedPartDto(
      catalogNumber: json['catalogNumber'] as String?,
      partName: json['partName'] as String,
      quantity: (json['quantity'] as num).toInt(),
    );
  }
}
