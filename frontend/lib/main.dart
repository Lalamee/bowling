import 'package:flutter/material.dart';
import 'package:flutter_application_1/api/api_core.dart';
import 'core/routing/app_router.dart';
import 'core/routing/routes.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiCore().init();
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: Routes.splash,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
