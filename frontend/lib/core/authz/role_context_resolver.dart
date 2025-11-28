import '../../models/user_info_dto.dart';
import 'role_access.dart';

class RoleContextResolver {
  static RoleAccountContext resolveFrom(UserInfoDto info) {
    final role = RoleAccessMatrix.parseRole(info.roleName) ?? _mapRoleId(info.roleId) ?? RoleAccessMatrix.parseRole(info.accountTypeName) ?? RoleName.mechanic;
    final accountType = RoleAccessMatrix.parseAccountType(info.accountTypeName) ?? _mapAccountTypeId(info.accountTypeId);
    return RoleAccountContext(role: role, accountType: accountType);
  }

  static RoleAccountContext? fromStored(String? role, String? accountType) {
    final parsedRole = RoleAccessMatrix.parseRole(role);
    if (parsedRole == null) return null;
    final parsedType = RoleAccessMatrix.parseAccountType(accountType);
    return RoleAccountContext(role: parsedRole, accountType: parsedType);
  }

  static RoleName? _mapRoleId(int? roleId) {
    switch (roleId) {
      case 1:
        return RoleName.admin;
      case 4:
        return RoleName.mechanic;
      case 5:
        return RoleName.clubOwner;
      case 6:
        return RoleName.headMechanic;
    }
    return null;
  }

  static AccountTypeName? _mapAccountTypeId(int? accountTypeId) {
    switch (accountTypeId) {
      case 1:
        return AccountTypeName.individual;
      case 2:
        return AccountTypeName.clubOwner;
      case 3:
        return AccountTypeName.clubManager;
      case 4:
        return AccountTypeName.freeMechanicBasic;
      case 5:
        return AccountTypeName.freeMechanicPremium;
      case 6:
        return AccountTypeName.mainAdmin;
    }
    return null;
  }
}
