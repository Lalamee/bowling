import '../routing/routes.dart';

/// Role names come from backend RoleName enum
enum RoleName {
  admin,
  mechanic,
  headMechanic,
  clubOwner,
}

/// Account type names come from backend AccountTypeName enum
enum AccountTypeName {
  individual,
  clubOwner,
  clubManager,
  freeMechanicBasic,
  freeMechanicPremium,
  mainAdmin,
}

extension AccountTypeNameApi on AccountTypeName {
  String get apiName {
    switch (this) {
      case AccountTypeName.individual:
        return 'INDIVIDUAL';
      case AccountTypeName.clubOwner:
        return 'CLUB_OWNER';
      case AccountTypeName.clubManager:
        return 'CLUB_MANAGER';
      case AccountTypeName.freeMechanicBasic:
        return 'FREE_MECHANIC_BASIC';
      case AccountTypeName.freeMechanicPremium:
        return 'FREE_MECHANIC_PREMIUM';
      case AccountTypeName.mainAdmin:
        return 'MAIN_ADMIN';
    }
  }
}

/// High level UI sections used for access control and menu filtering
enum AccessSection {
  mechanicCabinet,
  freeWarehouse,
  clubEquipment,
  maintenance,
  specialistsBase,
  supplyAcceptance,
  adminCabinet,
  notifications,
  technicalInfo,
  serviceJournal,
  staffManagement,
}

class RoleAccessConfig {
  final String homeRoute;
  final Set<AccessSection> allowedSections;

  const RoleAccessConfig({required this.homeRoute, required this.allowedSections});

  bool allows(AccessSection section) => allowedSections.contains(section);
}

class RoleAccessMatrix {
  static RoleAccessConfig resolve(RoleName role, AccountTypeName? type) {
    switch (role) {
      case RoleName.admin:
        final isMainAdmin = type == AccountTypeName.mainAdmin || type == null;
        return RoleAccessConfig(
          // Администраторов всегда отправляем на их профиль, чтобы избежать
          // загрузки механического кабинета при отсутствии типа аккаунта в кеше.
          homeRoute: Routes.profileAdmin,
          allowedSections: {
            if (isMainAdmin) ...{
              AccessSection.adminCabinet,
              AccessSection.notifications,
              AccessSection.specialistsBase,
              AccessSection.supplyAcceptance,
              AccessSection.serviceJournal,
              AccessSection.technicalInfo,
              AccessSection.staffManagement,
              AccessSection.maintenance,
              AccessSection.clubEquipment,
            } else ...{
              AccessSection.notifications,
            }
          },
        );
      case RoleName.clubOwner:
        return RoleAccessConfig(
          homeRoute: Routes.profileOwner,
          allowedSections: {
            AccessSection.notifications,
            AccessSection.specialistsBase,
            AccessSection.supplyAcceptance,
            AccessSection.technicalInfo,
            AccessSection.serviceJournal,
            AccessSection.staffManagement,
            AccessSection.maintenance,
            AccessSection.clubEquipment,
          },
        );
      case RoleName.headMechanic:
        return RoleAccessConfig(
          homeRoute: Routes.profileManager,
          allowedSections: {
            AccessSection.notifications,
            AccessSection.specialistsBase,
            AccessSection.supplyAcceptance,
            AccessSection.technicalInfo,
            AccessSection.serviceJournal,
            AccessSection.staffManagement,
            AccessSection.maintenance,
            AccessSection.clubEquipment,
          },
        );
      case RoleName.mechanic:
        if (type == AccountTypeName.freeMechanicBasic || type == AccountTypeName.freeMechanicPremium) {
          return RoleAccessConfig(
            homeRoute: Routes.profileMechanic,
            allowedSections: {
              AccessSection.mechanicCabinet,
              AccessSection.freeWarehouse,
              AccessSection.specialistsBase,
              AccessSection.notifications,
              AccessSection.maintenance,
            },
          );
        }
        return RoleAccessConfig(
          homeRoute: Routes.profileMechanic,
          allowedSections: {
            AccessSection.mechanicCabinet,
            AccessSection.notifications,
            AccessSection.maintenance,
            AccessSection.clubEquipment,
          },
        );
    }
  }

  static RoleName? parseRole(String? raw) {
    final normalized = raw?.trim().toUpperCase();
    switch (normalized) {
      case 'ADMIN':
        return RoleName.admin;
      case 'MECHANIC':
        return RoleName.mechanic;
      case 'HEAD_MECHANIC':
      case 'CLUB_MANAGER':
      case 'MANAGER':
        return RoleName.headMechanic;
      case 'CLUB_OWNER':
      case 'OWNER':
        return RoleName.clubOwner;
    }
    return null;
  }

  static AccountTypeName? parseAccountType(String? raw) {
    final normalized = raw?.trim().toUpperCase();
    switch (normalized) {
      case 'INDIVIDUAL':
        return AccountTypeName.individual;
      case 'CLUB_OWNER':
        return AccountTypeName.clubOwner;
      case 'CLUB_MANAGER':
        return AccountTypeName.clubManager;
      case 'FREE_MECHANIC_BASIC':
        return AccountTypeName.freeMechanicBasic;
      case 'FREE_MECHANIC_PREMIUM':
        return AccountTypeName.freeMechanicPremium;
      case 'MAIN_ADMIN':
        return AccountTypeName.mainAdmin;
    }
    return null;
  }
}

class RoleAccountContext {
  final RoleName role;
  final AccountTypeName? accountType;

  const RoleAccountContext({required this.role, required this.accountType});

  RoleAccessConfig get access => RoleAccessMatrix.resolve(role, accountType);
}
