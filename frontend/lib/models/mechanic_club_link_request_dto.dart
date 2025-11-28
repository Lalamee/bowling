class MechanicClubLinkRequestDto {
  final int? clubId;
  final bool attach;

  const MechanicClubLinkRequestDto({
    this.clubId,
    required this.attach,
  });

  Map<String, dynamic> toJson() => {
        'clubId': clubId,
        'attach': attach,
      };
}
