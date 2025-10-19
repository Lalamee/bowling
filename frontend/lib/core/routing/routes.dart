class Routes {
  static const splash = '/';
  static const splashFirstTime = '/splash-first-time';
  static const welcome = '/welcome';
  static const onboarding = '/onboarding';
  static const registerRole = '/register/role';
  static const registerMechanic = '/register/mechanic';
  static const registerOwner = '/register/owner';

  static const orders = '/orders';
  static const orderSummary = '/orders/summary';

  static const club = '/clubs';
  static const clubSearch = '/clubs/search';
  static const clubWarehouse = '/clubs/warehouse';

  static const profileMechanic = '/profile/mechanic';
  static const editMechanicProfile = '/profile/mechanic/edit';

  static const profileOwner = '/profile/owner';
  static const editOwnerProfile = '/profile/owner/edit';
  static const clubStaff = '/clubs/staff';

  static const knowledgeBase = '/kb';
  static const pdfReader = '/kb/pdf';

  static const authLogin = '/auth/login';
  static const recoverAsk = '/auth/recover/ask';
  static const recoverCode = '/auth/recover/code';
  static const recoverNewPass = '/auth/recover/new';

  static const profileManager = '/profile/manager';
  static const managerOrdersHistory = '/manager/orders/history';
  static const managerNotifications = '/manager/notifications';

  static const profileAdmin = '/profile/admin';
  static const adminClubs = '/admin/clubs';
  static const adminMechanics = '/admin/mechanics';
  static const adminOrders = '/admin/orders';
  static const adminProfile = '/admin/profile';

  static const ordersPersonalHistory = '/orders/history-personal';
  static const clubOrdersHistory = '/orders/history-club';
  
  static const maintenanceRequests = '/maintenance/requests';
  static const createMaintenanceRequest = '/maintenance/create';
  static const workLogs = '/worklogs';
  static const serviceHistory = '/service-history';
}
