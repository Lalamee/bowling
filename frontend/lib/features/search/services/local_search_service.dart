import '../../../core/models/order_status.dart';
import '../../../models/club_summary_dto.dart';
import '../../../models/maintenance_request_response_dto.dart';
import '../../../models/part_dto.dart';

class InventorySearchEntry {
  final PartDto part;
  final int? clubId;
  final String? clubName;

  const InventorySearchEntry({required this.part, this.clubId, this.clubName});
}

class ProfileSearchEntry {
  final String displayName;
  final String? phone;
  final String? email;
  final String route;
  final Object? arguments;
  final String? roleLabel;

  const ProfileSearchEntry({
    required this.displayName,
    required this.route,
    this.phone,
    this.email,
    this.arguments,
    this.roleLabel,
  });
}

class LocalSearchService {
  const LocalSearchService();

  List<MaintenanceRequestResponseDto> searchOrders(
    List<MaintenanceRequestResponseDto> source,
    String query, {
    Set<int>? allowedClubIds,
    bool includeAll = false,
  }) {
    final normalizedQuery = _normalize(query);
    final filteredByAccess = includeAll || allowedClubIds == null
        ? List<MaintenanceRequestResponseDto>.from(source)
        : source.where((order) {
            final clubId = order.clubId;
            if (clubId == null) return false;
            return allowedClubIds.contains(clubId);
          }).toList();

    if (normalizedQuery.isEmpty) {
      return filteredByAccess;
    }

    return filteredByAccess.where((order) {
      final buffer = StringBuffer()
        ..write(order.requestId)
        ..write(' ')
        ..write(order.clubName ?? '')
        ..write(' ')
        ..write(order.status ?? '')
        ..write(' ')
        ..write(describeOrderStatus(order.status))
        ..write(' ')
        ..write(order.mechanicName ?? '')
        ..write(' ')
        ..write(order.managerNotes ?? '');
      if (order.laneNumber != null) {
        buffer
          ..write(' ')
          ..write(order.laneNumber);
      }
      for (final part in order.requestedParts) {
        buffer
          ..write(' ')
          ..write(part.partName ?? '')
          ..write(' ')
          ..write(part.catalogNumber ?? '');
      }
      final haystack = _normalize(buffer.toString());
      return haystack.contains(normalizedQuery);
    }).toList();
  }

  List<ClubSummaryDto> searchClubs(
    List<ClubSummaryDto> source,
    String query, {
    Set<int>? allowedClubIds,
    bool includeAll = false,
  }) {
    final normalizedQuery = _normalize(query);
    final filteredByAccess = includeAll || allowedClubIds == null
        ? List<ClubSummaryDto>.from(source)
        : source.where((club) => allowedClubIds.contains(club.id)).toList();

    if (normalizedQuery.isEmpty) {
      return filteredByAccess;
    }

    return filteredByAccess.where((club) {
      final buffer = StringBuffer()
        ..write(club.name)
        ..write(' ')
        ..write(club.address ?? '')
        ..write(' ')
        ..write(club.contactPhone ?? '')
        ..write(' ')
        ..write(club.contactEmail ?? '')
        ..write(' ')
        ..write(club.id);
      final haystack = _normalize(buffer.toString());
      return haystack.contains(normalizedQuery);
    }).toList();
  }

  List<InventorySearchEntry> searchInventory(
    List<InventorySearchEntry> source,
    String query, {
    Set<int>? allowedClubIds,
    bool includeAll = false,
  }) {
    final normalizedQuery = _normalize(query);
    final filteredByAccess = includeAll || allowedClubIds == null
        ? List<InventorySearchEntry>.from(source)
        : source.where((entry) {
            final clubId = entry.clubId;
            if (clubId == null) return includeAll;
            return allowedClubIds.contains(clubId);
          }).toList();

    if (normalizedQuery.isEmpty) {
      return filteredByAccess;
    }

    return filteredByAccess.where((entry) {
      final part = entry.part;
      final buffer = StringBuffer()
        ..write(part.catalogNumber)
        ..write(' ')
        ..write(part.commonName ?? '')
        ..write(' ')
        ..write(part.officialNameRu ?? '')
        ..write(' ')
        ..write(part.officialNameEn ?? '')
        ..write(' ')
        ..write(part.location ?? '')
        ..write(' ')
        ..write(part.quantity ?? '')
        ..write(' ')
        ..write(entry.clubName ?? '');
      final haystack = _normalize(buffer.toString());
      return haystack.contains(normalizedQuery);
    }).toList();
  }

  List<ProfileSearchEntry> searchProfiles(
    List<ProfileSearchEntry> source,
    String query,
  ) {
    final normalizedQuery = _normalize(query);
    if (normalizedQuery.isEmpty) {
      return List<ProfileSearchEntry>.from(source);
    }

    return source.where((profile) {
      final buffer = StringBuffer()
        ..write(profile.displayName)
        ..write(' ')
        ..write(profile.roleLabel ?? '')
        ..write(' ')
        ..write(profile.phone ?? '')
        ..write(' ')
        ..write(profile.email ?? '');
      final haystack = _normalize(buffer.toString());
      return haystack.contains(normalizedQuery);
    }).toList();
  }

  String _normalize(String input) {
    final lower = input.toLowerCase().trim();
    return lower.replaceAll(RegExp(r'\s+'), ' ');
  }
}
