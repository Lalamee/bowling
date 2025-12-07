class AdminStaffStatusUpdateDto {
  final bool? active;
  final bool? infoAccessRestricted;

  const AdminStaffStatusUpdateDto({this.active, this.infoAccessRestricted});

  Map<String, dynamic> toJson() => {
        'active': active,
        'infoAccessRestricted': infoAccessRestricted,
      };
}

