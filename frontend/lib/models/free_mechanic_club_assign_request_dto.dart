class FreeMechanicClubAssignRequestDto {
  final int? clubId;

  const FreeMechanicClubAssignRequestDto({this.clubId});

  Map<String, dynamic> toJson() => {
        'clubId': clubId,
      };
}
