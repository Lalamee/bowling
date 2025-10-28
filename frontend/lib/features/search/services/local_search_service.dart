import '../../../models/club_summary_dto.dart';
import '../../../models/maintenance_request_response_dto.dart';

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

  String _normalize(String input) {
    final lower = input.toLowerCase().trim();
    return lower.replaceAll(RegExp(r'\s+'), ' ');
  }
}
