import 'package:bowling_market/core/authz/role_access.dart';
import 'package:bowling_market/core/authz/role_context_resolver.dart';
import 'package:bowling_market/core/routing/routes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RoleAccessMatrix', () {
    test('free mechanic basic is routed to mechanic cabinet without club sections', () {
      final ctx = RoleAccountContext(role: RoleName.mechanic, accountType: AccountTypeName.freeMechanicBasic);
      expect(ctx.access.homeRoute, Routes.profileMechanic);
      expect(ctx.access.allows(AccessSection.freeWarehouse), isTrue);
      expect(ctx.access.allows(AccessSection.clubEquipment), isFalse);
    });

    test('club mechanic keeps maintenance access and club visibility', () {
      final ctx = RoleAccountContext(role: RoleName.mechanic, accountType: AccountTypeName.individual);
      expect(ctx.access.allows(AccessSection.maintenance), isTrue);
      expect(ctx.access.allows(AccessSection.clubEquipment), isTrue);
      expect(ctx.access.homeRoute, Routes.profileMechanic);
    });

    test('owner and manager land on their dashboards with tech info', () {
      final owner = RoleAccessMatrix.resolve(RoleName.clubOwner, AccountTypeName.clubOwner);
      expect(owner.homeRoute, Routes.profileOwner);
      expect(owner.allows(AccessSection.technicalInfo), isTrue);

      final manager = RoleAccessMatrix.resolve(RoleName.headMechanic, AccountTypeName.clubManager);
      expect(manager.homeRoute, Routes.profileManager);
      expect(manager.allows(AccessSection.technicalInfo), isTrue);
    });

    test('admin sees cabinet and service journal', () {
      final ctx = RoleAccessMatrix.resolve(RoleName.admin, AccountTypeName.mainAdmin);
      expect(ctx.homeRoute, Routes.profileAdmin);
      expect(ctx.allows(AccessSection.adminCabinet), isTrue);
      expect(ctx.allows(AccessSection.serviceJournal), isTrue);
    });

    test('admin without MAIN_ADMIN account type is limited to notifications', () {
      final ctx = RoleAccessMatrix.resolve(RoleName.admin, AccountTypeName.individual);
      expect(ctx.homeRoute, Routes.profileMechanic);
      expect(ctx.allows(AccessSection.adminCabinet), isFalse);
      expect(ctx.allows(AccessSection.notifications), isTrue);
      expect(ctx.allowedSections.length, 1);
    });
  });

  group('RoleContextResolver', () {
    test('parses stored lowercase values', () {
      final ctx = RoleContextResolver.fromStored('mechanic', 'free_mechanic_premium');
      expect(ctx?.role, RoleName.mechanic);
      expect(ctx?.accountType, AccountTypeName.freeMechanicPremium);
    });
  });
}
