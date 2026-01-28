import 'package:flutter/material.dart';
import 'package:bowling_market/features/orders/presentation/screens/admin_orders_screen.dart';
import 'package:bowling_market/features/profile/admin/presentation/screens/admin_clubs_screen.dart';
import 'package:bowling_market/features/profile/admin/presentation/screens/admin_content_tools_screen.dart';
import 'package:bowling_market/features/profile/admin/presentation/screens/admin_knowledge_base_upload_screen.dart';
import 'package:bowling_market/features/profile/admin/presentation/screens/admin_mechanics_screen.dart';
import 'package:bowling_market/features/profile/admin/presentation/screens/admin_parts_catalog_create_screen.dart';
import 'package:bowling_market/features/profile/admin/presentation/screens/admin_profile_screen.dart';
import 'package:bowling_market/features/profile/admin/presentation/screens/admin_registrations_screen.dart';
import 'package:bowling_market/features/orders/notifications/admin_appeals_screen.dart';
import 'package:bowling_market/features/orders/presentation/screens/supply_acceptance_screen.dart';
import 'package:bowling_market/features/orders/presentation/screens/supply_archive_screen.dart';
import 'package:bowling_market/features/orders/presentation/screens/supply_order_details_screen.dart';
import 'routes.dart';
import 'route_args.dart';

import '../../features/onboarding/presentation/screens/splash_screen.dart';
import '../../features/onboarding/presentation/screens/splash_first_time.dart';
import '../../features/onboarding/presentation/screens/welcome_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/onboarding/presentation/screens/register_role_selection.dart';

import '../../features/register/mechanic/presentation/screens/register_mechanic_screen.dart';
import '../../features/register/owner/presentation/screens/register_owner_screen.dart';
import '../../features/register/manager/presentation/screens/register_manager_screen.dart';

import '../../features/orders/presentation/screens/orders_screen.dart';
import '../../features/orders/presentation/screens/order_summary_screen.dart';
import '../../features/orders/presentation/screens/manager_orders_history_screen.dart';
import '../../features/orders/presentation/screens/club_orders_history_screen.dart';
import '../../features/orders/presentation/screens/maintenance_requests_screen.dart';
import '../../features/orders/presentation/screens/create_maintenance_request_screen.dart';
import '../../features/orders/presentation/screens/work_logs_screen.dart';
import '../../features/orders/presentation/screens/service_history_screen.dart';

import '../../features/clubs/presentation/screens/club_screen.dart';
import '../../features/clubs/presentation/screens/club_search_screen.dart';
import '../../features/clubs/presentation/screens/club_warehouse_screen.dart';
import '../../features/clubs/presentation/screens/club_lanes_screen.dart';
import '../../features/clubs/presentation/screens/owner_dashboard_screen.dart';
import '../../features/clubs/presentation/screens/club_staff_screen.dart';
import '../../features/clubs/presentation/screens/warehouse_selector_screen.dart';
import '../../features/warehouse/presentation/personal_warehouse_screen.dart';

import '../../features/profile/mechanic/presentation/screens/mechanic_profile_screen.dart';
import '../../features/profile/mechanic/presentation/screens/edit_mechanic_profile_screen.dart';
import '../../features/profile/mechanic/presentation/screens/favorites_screen.dart';
import '../../features/specialists/presentation/screens/attestation_applications_screen.dart';
import '../../features/specialists/presentation/screens/admin_attestation_screen.dart';
import '../../features/specialists/presentation/screens/specialists_list_screen.dart';

import '../../features/profile/owner/presentation/screens/owner_profile_screen.dart';
import '../../features/profile/owner/presentation/screens/edit_owner_profile_screen.dart';

import '../../features/profile/manager/presentation/screens/manager_profile_screen.dart';
import '../../features/orders/notifications/notifications_page.dart';
import '../../features/orders/notifications/admin_help_requests_screen.dart';
import '../../features/orders/notifications/admin_complaints_screen.dart';

import '../../features/knowledge_base/presentation/screens/knowledge_base_screen.dart';
import '../../features/knowledge_base/presentation/screens/pdf_reader_screen.dart';

import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/recover_ask_login_screen.dart';
import '../../features/auth/presentation/screens/recover_code_screen.dart';
import '../../features/auth/presentation/screens/recover_new_password_screen.dart';
import '../../features/support/presentation/screens/support_request_screen.dart';

class AppRouter {
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case Routes.splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case Routes.splashFirstTime:
        return MaterialPageRoute(builder: (_) => const SplashFirstTime());
      case Routes.welcome:
        return MaterialPageRoute(builder: (_) => const WelcomeScreen());
      case Routes.onboarding:
        return MaterialPageRoute(builder: (_) => const OnboardingScreen());
      case Routes.registerRole:
        return MaterialPageRoute(builder: (_) => const RegisterRoleSelectionScreen());
      case Routes.registerMechanic:
        return MaterialPageRoute(builder: (_) => const RegisterMechanicScreen());
      case Routes.registerOwner:
        return MaterialPageRoute(builder: (_) => const RegisterOwnerScreen());
      case Routes.registerManager:
        return MaterialPageRoute(builder: (_) => const RegisterManagerScreen());

      case Routes.orders:
        return MaterialPageRoute(builder: (_) => const OrdersScreen());
      case Routes.orderSummary:
        final args = settings.arguments as OrderSummaryArgs?;
        if (args == null) {
          return MaterialPageRoute(builder: (_) => const OrdersScreen());
        }
        return MaterialPageRoute(
          builder: (_) => OrderSummaryScreen(
            order: args.order,
            orderNumber: args.orderNumber,
          ),
        );

      case Routes.club:
        int? initialClubId;
        final args = settings.arguments;
        if (args is int) {
          initialClubId = args;
        } else if (args is Map) {
          final map = Map<String, dynamic>.from(args as Map);
          final value = map['clubId'];
          if (value is int) {
            initialClubId = value;
          } else if (value is num) {
            initialClubId = value.toInt();
          }
        }
        return MaterialPageRoute(builder: (_) => ClubScreen(initialClubId: initialClubId));
      case Routes.clubSearch:
        return MaterialPageRoute(builder: (_) => const ClubSearchScreen());
      case Routes.clubWarehouse:
        final args = settings.arguments as ClubWarehouseArgs?;
        if (args == null) {
          return MaterialPageRoute(builder: (_) => const ClubScreen());
        }
        final warehouseId = args.warehouseId ?? args.clubId;
        if (warehouseId == null) {
          return MaterialPageRoute(builder: (_) => const ClubScreen());
        }
        return MaterialPageRoute(
          builder: (_) => ClubWarehouseScreen(
            warehouseId: warehouseId,
            clubId: args.clubId ?? warehouseId,
            clubName: args.clubName,
            warehouseType: args.warehouseType,
            initialInventoryId: args.inventoryId,
            initialQuery: args.searchQuery,
          ),
        );
      case Routes.personalWarehouse:
        return MaterialPageRoute(builder: (_) => const PersonalWarehouseScreen());
      case Routes.warehouseSelector:
        final args = settings.arguments as WarehouseSelectorArgs?;
        return MaterialPageRoute(
          builder: (_) => WarehouseSelectorScreen(preferredClubId: args?.preferredClubId),
        );
      case Routes.clubLanes:
        final args = settings.arguments as ClubLanesArgs?;
        if (args == null) {
          return MaterialPageRoute(builder: (_) => const ClubScreen());
        }
        return MaterialPageRoute(
          builder: (_) => ClubLanesScreen(
            clubId: args.clubId,
            clubName: args.clubName,
            lanesCount: args.lanesCount,
          ),
        );
      case Routes.ownerDashboard:
        int? clubId;
        final args = settings.arguments;
        if (args is int) {
          clubId = args;
        } else if (args is Map) {
          final map = Map<String, dynamic>.from(args as Map);
          final val = map['clubId'];
          if (val is num) clubId = val.toInt();
        }
        return MaterialPageRoute(builder: (_) => OwnerDashboardScreen(initialClubId: clubId));
      case Routes.clubStaff:
        return MaterialPageRoute(builder: (_) => const ClubStaffScreen());

      case Routes.profileMechanic:
        return MaterialPageRoute(builder: (_) => const MechanicProfileScreen());
      case Routes.editMechanicProfile: {
        final args = settings.arguments as EditMechanicProfileArgs?;
        return MaterialPageRoute(builder: (_) => EditMechanicProfileScreen(mechanicId: args?.mechanicId));
      }
      case Routes.specialistsDirectory:
        return MaterialPageRoute(builder: (_) => const SpecialistsListScreen());
      case Routes.attestationApplications:
        return MaterialPageRoute(builder: (_) => const AttestationApplicationsScreen());
      case Routes.supportAppeal:
        return MaterialPageRoute(builder: (_) => const SupportRequestScreen());

      case Routes.profileOwner:
        return MaterialPageRoute(builder: (_) => const OwnerProfileScreen());
      case Routes.editOwnerProfile:
        return MaterialPageRoute(builder: (_) => const EditOwnerProfileScreen());
      case Routes.favorites:
        return MaterialPageRoute(builder: (_) => const FavoritesScreen());

      case Routes.knowledgeBase:
        return MaterialPageRoute(builder: (_) => const KnowledgeBaseScreen());
      case Routes.pdfReader: {
        final args = settings.arguments as PdfReaderArgs?;
        if (args == null) {
          return MaterialPageRoute(builder: (_) => const KnowledgeBaseScreen());
        }
        return MaterialPageRoute(builder: (_) => PdfReaderScreen(doc: args.document));
      }

      case Routes.authLogin:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case Routes.recoverAsk:
        return MaterialPageRoute(builder: (_) => const RecoverAskLoginScreen());
      case Routes.recoverCode:
        return MaterialPageRoute(builder: (_) => const RecoverCodeScreen());
      case Routes.recoverNewPass:
        return MaterialPageRoute(builder: (_) => const RecoverNewPasswordScreen());

      case Routes.profileManager:
        return MaterialPageRoute(builder: (_) => const ManagerProfileScreen());
      case Routes.managerOrdersHistory:
        return MaterialPageRoute(builder: (_) => const ManagerOrdersHistoryScreen());
      case Routes.managerNotifications:
        return MaterialPageRoute(builder: (_) => const NotificationsPage());

      case Routes.ordersPersonalHistory:
        return MaterialPageRoute(builder: (_) => const ManagerOrdersHistoryScreen());
      case Routes.clubOrdersHistory:
        return MaterialPageRoute(builder: (_) => const ClubOrdersHistoryScreen());
      case Routes.supplyAcceptance:
        return MaterialPageRoute(builder: (_) => const SupplyAcceptanceScreen());
      case Routes.supplyArchive:
        return MaterialPageRoute(builder: (_) => const SupplyArchiveScreen());
      case Routes.supplyOrderDetails:
        final args = settings.arguments as SupplyOrderDetailsArgs?;
        if (args == null) {
          return MaterialPageRoute(builder: (_) => const SupplyAcceptanceScreen());
        }
        return MaterialPageRoute(
          builder: (_) => SupplyOrderDetailsScreen(orderId: args.orderId, initialSummary: args.summary),
        );

      case Routes.profileAdmin:
        return MaterialPageRoute(builder: (_) => const AdminProfileScreen());
      case Routes.adminClubs:
        return MaterialPageRoute(builder: (_) => const AdminClubsScreen());
      case Routes.adminMechanics:
        final args = settings.arguments;
        var isClubOwner = false;
        if (args is Map) {
          final value = args['isClubOwner'];
          if (value is bool) {
            isClubOwner = value;
          }
        }
        return MaterialPageRoute(builder: (_) => AdminMechanicsScreen(isClubOwner: isClubOwner));
      case Routes.adminOrders:
        return MaterialPageRoute(builder: (_) => const AdminOrdersScreen());
      case Routes.adminAttestations:
        return MaterialPageRoute(builder: (_) => const AdminAttestationScreen());
      case Routes.adminHelpRequests:
        return MaterialPageRoute(builder: (_) => const AdminHelpRequestsScreen());
      case Routes.adminRegistrations:
        return MaterialPageRoute(builder: (_) => const AdminRegistrationsScreen());
      case Routes.adminComplaints:
        return MaterialPageRoute(builder: (_) => const AdminComplaintsScreen());
      case Routes.adminAppeals:
        return MaterialPageRoute(builder: (_) => const AdminAppealsScreen());
      case Routes.adminContentTools:
        return MaterialPageRoute(builder: (_) => const AdminContentToolsScreen());
      case Routes.adminKnowledgeBaseUpload:
        return MaterialPageRoute(builder: (_) => const AdminKnowledgeBaseUploadScreen());
      case Routes.adminPartsCatalogCreate:
        return MaterialPageRoute(builder: (_) => const AdminPartsCatalogCreateScreen());

      case Routes.maintenanceRequests:
        return MaterialPageRoute(builder: (_) => const MaintenanceRequestsScreen());
      case Routes.createMaintenanceRequest:
        int? initialClubId;
        final args = settings.arguments;
        if (args is Map) {
          final value = args['clubId'];
          if (value is int) {
            initialClubId = value;
          } else if (value is num) {
            initialClubId = value.toInt();
          }
        } else if (args is int) {
          initialClubId = args;
        } else if (args is num) {
          initialClubId = args.toInt();
        }
        return MaterialPageRoute(
          builder: (_) => CreateMaintenanceRequestScreen(initialClubId: initialClubId),
        );
      case Routes.workLogs:
        return MaterialPageRoute(builder: (_) => const WorkLogsScreen());
      case Routes.serviceHistory:
        return MaterialPageRoute(builder: (_) => const ServiceHistoryScreen());
    }
    return null;
  }
}
