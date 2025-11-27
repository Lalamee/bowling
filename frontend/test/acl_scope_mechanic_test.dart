import 'package:test/test.dart';

import 'package:bowling_app/core/services/authz/acl.dart';
import 'package:bowling_app/models/maintenance_request_response_dto.dart';

void main() {
  RequestPartResponseDto _part() => RequestPartResponseDto(partId: 1);

  test('mechanic can view own request without club binding', () {
    final scope = UserAccessScope(
      role: 'mechanic',
      accessibleClubIds: const <int>{},
      userId: 10,
      mechanicProfileId: 77,
      accountTypeName: 'FREE_MECHANIC_BASIC',
    );

    final order = MaintenanceRequestResponseDto(
      requestId: 1,
      clubId: null,
      mechanicId: 77,
      requestedParts: [_part()],
    );

    expect(scope.canViewOrder(order), isTrue);
  });

  test('mechanic can view club request when club is accessible', () {
    final scope = UserAccessScope(
      role: 'mechanic',
      accessibleClubIds: const {5},
      userId: 10,
      mechanicProfileId: 99,
      accountTypeName: 'INDIVIDUAL',
    );

    final order = MaintenanceRequestResponseDto(
      requestId: 2,
      clubId: 5,
      mechanicId: 101,
      requestedParts: [_part()],
    );

    expect(scope.canViewOrder(order), isTrue);
  });

  test('mechanic cannot view other club without match', () {
    final scope = UserAccessScope(
      role: 'mechanic',
      accessibleClubIds: const {2},
      userId: 10,
      mechanicProfileId: 9,
      accountTypeName: 'FREE_MECHANIC_PREMIUM',
    );

    final order = MaintenanceRequestResponseDto(
      requestId: 3,
      clubId: 4,
      mechanicId: 11,
      requestedParts: [_part()],
    );

    expect(scope.canViewOrder(order), isFalse);
  });
}
