import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/orders/presentation/screens/admin_orders_screen.dart';
import 'package:flutter_application_1/features/profile/admin/presentation/screens/admin_clubs_screen.dart';
import 'package:flutter_application_1/features/profile/admin/presentation/screens/admin_mechanics_screen.dart';
import 'package:flutter_application_1/features/profile/admin/presentation/screens/admin_profile_screen.dart';
import 'routes.dart';
import 'route_args.dart';

import '../../features/onboarding/presentation/screens/splash_screen.dart';
import '../../features/onboarding/presentation/screens/splash_first_time.dart';
import '../../features/onboarding/presentation/screens/welcome_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/onboarding/presentation/screens/register_role_selection.dart';

import '../../features/register/mechanic/presentation/screens/register_mechanic_screen.dart';
import '../../features/register/owner/presentation/screens/register_owner_screen.dart';

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
import '../../features/clubs/presentation/screens/club_staff_screen.dart';

import '../../features/profile/mechanic/presentation/screens/mechanic_profile_screen.dart';
import '../../features/profile/mechanic/presentation/screens/edit_mechanic_profile_screen.dart';

import '../../features/profile/owner/presentation/screens/owner_profile_screen.dart';
import '../../features/profile/owner/presentation/screens/edit_owner_profile_screen.dart';

import '../../features/profile/manager/presentation/screens/manager_profile_screen.dart';
import '../../features/profile/manager/presentation/screens/manager_notifications_screen.dart';

import '../../features/knowledge_base/presentation/screens/knowledge_base_screen.dart';
import '../../features/knowledge_base/presentation/screens/pdf_reader_screen.dart';

import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/recover_ask_login_screen.dart';
import '../../features/auth/presentation/screens/recover_code_screen.dart';
import '../../features/auth/presentation/screens/recover_new_password_screen.dart';

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
        return MaterialPageRoute(builder: (_) => const ClubScreen());
      case Routes.clubSearch:
        return MaterialPageRoute(builder: (_) => const ClubSearchScreen());
      case Routes.clubWarehouse:
        return MaterialPageRoute(builder: (_) => const ClubWarehouseScreen());
      case Routes.clubStaff:
        return MaterialPageRoute(builder: (_) => const ClubStaffScreen());

      case Routes.profileMechanic:
        return MaterialPageRoute(builder: (_) => const MechanicProfileScreen());
      case Routes.editMechanicProfile: {
        final args = settings.arguments as EditMechanicProfileArgs?;
        return MaterialPageRoute(builder: (_) => EditMechanicProfileScreen(mechanicId: args?.mechanicId));
      }

      case Routes.profileOwner:
        return MaterialPageRoute(builder: (_) => const OwnerProfileScreen());
      case Routes.editOwnerProfile:
        return MaterialPageRoute(builder: (_) => const EditOwnerProfileScreen());

      case Routes.knowledgeBase:
        return MaterialPageRoute(builder: (_) => const KnowledgeBaseScreen());
      case Routes.pdfReader: {
        final args = settings.arguments as PdfReaderArgs?;
        if (args == null) return MaterialPageRoute(builder: (_) => const KnowledgeBaseScreen());
        return MaterialPageRoute(builder: (_) => PdfReaderScreen(assetPath: args.assetPath, title: args.title));
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
        return MaterialPageRoute(builder: (_) => const ManagerNotificationsScreen());

      case Routes.ordersPersonalHistory:
        return MaterialPageRoute(builder: (_) => const ManagerOrdersHistoryScreen());
      case Routes.clubOrdersHistory:
        return MaterialPageRoute(builder: (_) => const ClubOrdersHistoryScreen());

      case Routes.profileAdmin:
        return MaterialPageRoute(builder: (_) => const AdminProfileScreen());
      case Routes.adminClubs:
        return MaterialPageRoute(builder: (_) => const AdminClubsScreen());
      case Routes.adminMechanics:
        return MaterialPageRoute(builder: (_) => const AdminMechanicsScreen());
      case Routes.adminOrders:
        return MaterialPageRoute(builder: (_) => const AdminOrdersScreen());
      
      case Routes.maintenanceRequests:
        return MaterialPageRoute(builder: (_) => const MaintenanceRequestsScreen());
      case Routes.createMaintenanceRequest:
        return MaterialPageRoute(builder: (_) => const CreateMaintenanceRequestScreen());
      case Routes.workLogs:
        return MaterialPageRoute(builder: (_) => const WorkLogsScreen());
      case Routes.serviceHistory:
        return MaterialPageRoute(builder: (_) => const ServiceHistoryScreen());
    }
    return null;
  }
}
