class PartsSearchDto {
  String? searchQuery;
  int? manufacturerId;
  String? catalogNumber;
  bool? isUnique;
  String? equipmentType;
  String? categoryCode;
  int page;
  int size;
  String sortBy;
  String sortDirection;

  PartsSearchDto({
    this.searchQuery,
    this.manufacturerId,
    this.catalogNumber,
    this.isUnique,
    this.equipmentType,
    this.categoryCode,
    this.page = 0,
    this.size = 20,
    this.sortBy = 'catalogId',
    this.sortDirection = 'ASC',
  });

  Map<String, dynamic> toJson() => {
        'searchQuery': searchQuery,
        'manufacturerId': manufacturerId,
        'catalogNumber': catalogNumber,
        'isUnique': isUnique,
        'equipmentType': equipmentType,
        'categoryCode': categoryCode,
        'page': page,
        'size': size,
        'sortBy': sortBy,
        'sortDirection': sortDirection,
      };
}
