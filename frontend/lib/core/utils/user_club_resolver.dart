import '../models/user_club.dart';

List<UserClub> resolveUserClubs(Map<String, dynamic>? source) {
  if (source == null) {
    return const [];
  }

  final result = <UserClub>[];
  final indexById = <int, int>{};

  String? _asString(dynamic value) {
    if (value == null) return null;
    final str = value.toString().trim();
    return str.isEmpty ? null : str;
  }

  int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  String _mergeName(dynamic incoming, String? current, int id) {
    final candidate = _asString(incoming);
    final existing = current?.trim();
    if (candidate == null || candidate.isEmpty) {
      if (existing != null && existing.isNotEmpty) return existing;
      return 'Клуб #$id';
    }
    if (existing == null || existing.isEmpty) {
      return candidate;
    }
    final normalizedExisting = existing.toLowerCase();
    if (normalizedExisting.startsWith('клуб #') || normalizedExisting.startsWith('club #')) {
      return candidate;
    }
    if (candidate.length > existing.length) {
      return candidate;
    }
    return existing;
  }

  String? _mergeField(dynamic incoming, String? current) {
    final candidate = _asString(incoming);
    if (candidate == null) return current;
    if (current == null || current.isEmpty) return candidate;
    if (candidate.length > current.length) return candidate;
    return current;
  }

  void add({
    dynamic id,
    dynamic name,
    dynamic address,
    dynamic lanes,
    dynamic equipment,
    dynamic phone,
    dynamic email,
  }) {
    final resolvedId = _asInt(id);
    if (resolvedId == null) return;

    final index = indexById[resolvedId];
    final existing = index != null ? result[index] : null;

    final merged = UserClub(
      id: resolvedId,
      name: _mergeName(name, existing?.name, resolvedId),
      address: _mergeField(address, existing?.address),
      lanes: _mergeField(lanes, existing?.lanes),
      equipment: _mergeField(equipment, existing?.equipment),
      phone: _mergeField(phone, existing?.phone),
      email: _mergeField(email, existing?.email),
    );

    if (index != null) {
      result[index] = merged;
    } else {
      indexById[resolvedId] = result.length;
      result.add(merged);
    }
  }

  void addFromMap(Map<String, dynamic> map) {
    add(
      id: map['id'] ?? map['clubId'],
      name: map['name'] ?? map['clubName'] ?? map['legalName'],
      address: map['address'] ?? map['clubAddress'] ?? map['legalAddress'],
      lanes: map['lanes'] ?? map['lanesCount'],
      equipment: map['equipment'],
      phone: map['contactPhone'] ?? map['clubPhone'] ?? map['phone'],
      email: map['contactEmail'] ?? map['email'],
    );
  }

  void extractFromProfile(dynamic profile) {
    if (profile is! Map) return;
    final map = Map<String, dynamic>.from(profile as Map);

    final detailed = map['clubsDetailed'];
    if (detailed is Iterable) {
      for (final entry in detailed) {
        if (entry is Map) {
          addFromMap(Map<String, dynamic>.from(entry));
        }
      }
    }

    final clubs = map['clubs'];
    if (clubs is Iterable) {
      for (final entry in clubs) {
        if (entry is Map) {
          addFromMap(Map<String, dynamic>.from(entry));
        } else {
          add(
            id: map['clubId'],
            name: entry,
            address: map['address'] ?? map['clubAddress'] ?? map['legalAddress'],
            lanes: map['lanes'] ?? map['lanesCount'],
            equipment: map['equipment'],
            phone: map['contactPhone'],
            email: map['contactEmail'],
          );
        }
      }
    } else if (clubs is Map) {
      addFromMap(Map<String, dynamic>.from(clubs));
    } else if (clubs != null) {
      add(
        id: map['clubId'],
        name: clubs,
        address: map['address'] ?? map['clubAddress'] ?? map['legalAddress'],
        lanes: map['lanes'] ?? map['lanesCount'],
        equipment: map['equipment'],
        phone: map['contactPhone'],
        email: map['contactEmail'],
      );
    }

    final singleClub = map['club'];
    if (singleClub is Map) {
      addFromMap(Map<String, dynamic>.from(singleClub));
    }

    add(
      id: map['clubId'],
      name: map['clubName'] ?? map['name'] ?? map['legalName'],
      address: map['address'] ?? map['clubAddress'] ?? map['legalAddress'],
      lanes: map['lanes'] ?? map['lanesCount'],
      equipment: map['equipment'],
      phone: map['contactPhone'] ?? map['clubPhone'],
      email: map['contactEmail'],
    );
  }

  void extractFromDynamic(dynamic value) {
    if (value is Map) {
      addFromMap(Map<String, dynamic>.from(value));
    } else if (value is Iterable) {
      for (final entry in value) {
        if (entry is Map) {
          addFromMap(Map<String, dynamic>.from(entry));
        }
      }
    }
  }

  extractFromProfile(source['mechanicProfile']);
  extractFromProfile(source['ownerProfile']);
  extractFromProfile(source['managerProfile']);

  extractFromDynamic(source['clubsDetailed']);
  extractFromDynamic(source['clubs']);

  final topClub = source['club'];
  if (topClub is Map) {
    addFromMap(Map<String, dynamic>.from(topClub));
  }

  add(
    id: source['clubId'],
    name: source['clubName'] ?? source['company'] ?? source['legalName'],
    address: source['address'] ?? source['clubAddress'] ?? source['legalAddress'],
    lanes: source['lanes'] ?? source['lanesCount'],
    equipment: source['equipment'],
    phone: source['contactPhone'] ?? source['clubPhone'] ?? source['phone'],
    email: source['contactEmail'] ?? source['email'],
  );

  return result;
}
