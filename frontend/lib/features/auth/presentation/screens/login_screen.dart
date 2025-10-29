import 'package:dio/dio.dart';

import '../../../../api/api_core.dart';
import '../../../../core/utils/net_ui.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/local_auth_storage.dart';
import '../../../../core/utils/phone_utils.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/routing/routes.dart';
import '../../../../shared/widgets/titles/bowling_market_title.dart';
import '../widgets/brand_button.dart';
import '../widgets/inputs.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _login = TextEditingController();
  final _password = TextEditingController();
  late final FocusNode _loginFocus;

  @override
  void initState() {
    super.initState();
    _loginFocus = FocusNode();
    if (_login.text.isEmpty) {
      _login.text = '+7 ';
      _login.selection = TextSelection.fromPosition(TextPosition(offset: _login.text.length));
    }
    _loginFocus.addListener(() {
      if (_loginFocus.hasFocus && (_login.text.isEmpty || _login.text == '+7')) {
        _login.text = '+7 ';
        _login.selection = TextSelection.fromPosition(TextPosition(offset: _login.text.length));
      }
    });
  }

  @override
  void dispose() {
    _loginFocus.dispose();
    _login.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _onLogin() async {
    final phone = _login.text.trim();
    if (phone.isEmpty || phone == '+7') {
      showSnack(context, 'Введите телефон и пароль');
      return;
    }
    final normalizedPhone = PhoneUtils.normalize(phone);
    final password = _password.text;
    if (phone.isEmpty || password.isEmpty) {
      showSnack(context, 'Введите телефон и пароль');
      return;
    }
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    bool loaderClosed = false;
    void closeLoader() {
      if (!mounted || loaderClosed) return;
      final navigator = Navigator.of(context, rootNavigator: true);
      if (navigator.canPop()) {
        navigator.pop();
      }
      loaderClosed = true;
    }

    try {
      final res = await AuthService.login(phone: normalizedPhone, password: password);
      closeLoader();
      if (res == null || !mounted) {
        return;
      }
      final role = await _cacheRole();
      if (!mounted) return;
      final destination = _routeForRole(role);
      Navigator.of(context).pushReplacementNamed(destination);
    } on DioException catch (e) {
      final api = e.error is ApiException ? e.error as ApiException : null;
      closeLoader();
      if (!mounted) return;
      if (api != null) {
        if (api.statusCode == 403) {
          showSnack(context, 'Аккаунт не активирован. Обратитесь к владельцу клуба.');
          return;
        }
        if (api.statusCode == 401) {
          showSnack(context, 'Неверный телефон или пароль');
          return;
        }
      }
      showApiError(context, api ?? e);
    } on ApiException catch (e) {
      closeLoader();
      if (!mounted) return;
      if (e.statusCode == 403) {
        showSnack(context, 'Аккаунт не активирован. Обратитесь к владельцу клуба.');
        return;
      }
      if (e.statusCode == 401) {
        showSnack(context, 'Неверный телефон или пароль');
        return;
      }
      showSnack(context, e.message);
    } catch (e) {
      closeLoader();
      if (!mounted) return;
      showApiError(context, e);
    }
  }

  Future<String?> _cacheRole() async {
    final info = await AuthService.currentUser();
    if (info == null) return null;

    String? role;
    String? normalize(String? value) => value?.toLowerCase().trim();

    final typeName = normalize(info.accountTypeName);
    if (typeName != null && typeName.isNotEmpty) {
      if (typeName.contains('влад') || typeName.contains('owner')) {
        role = 'owner';
      } else if (typeName.contains('менедж') || typeName.contains('главн')) {
        role = 'manager';
      } else if (typeName.contains('админ')) {
        role = 'admin';
      } else if (typeName.contains('механ')) {
        role = 'mechanic';
      }
    }

    if (role == null) {
      final roleName = normalize(info.roleName);
      if (roleName != null && roleName.isNotEmpty) {
        if (roleName.contains('admin')) {
          role = 'admin';
        } else if (roleName.contains('owner')) {
          role = 'owner';
        } else if (roleName.contains('manager') || roleName.contains('staff') || roleName.contains('head')) {
          role = 'manager';
        } else if (roleName.contains('mechanic')) {
          role = 'mechanic';
        }
      }
    }

    if (role == null && info.roleId != null) {
      switch (info.roleId) {
        case 1:
          role = 'admin';
          break;
        case 4:
          role = 'mechanic';
          break;
        case 5:
          role = 'owner';
          break;
        case 6:
          role = 'manager';
          break;
      }
    }

    if (role == null && info.accountTypeId != null) {
      switch (info.accountTypeId) {
        case 2:
          role = 'owner';
          break;
        case 1:
          role = 'mechanic';
          break;
      }
    }

    if (role == null) return null;

    if (role == 'mechanic') {
      await LocalAuthStorage.clearOwnerState();
      await LocalAuthStorage.setMechanicRegistered(true);
    } else if (role == 'owner') {
      await LocalAuthStorage.clearMechanicState();
      await LocalAuthStorage.setOwnerRegistered(true);
    } else {
      await LocalAuthStorage.clearMechanicState();
      await LocalAuthStorage.clearOwnerState();
    }

    await LocalAuthStorage.setRegisteredRole(role);
    return role;
  }

  String _routeForRole(String? role) {
    switch (role) {
      case 'owner':
        return Routes.profileOwner;
      case 'manager':
        return Routes.profileManager;
      case 'admin':
        return Routes.profileAdmin;
      default:
        return Routes.profileMechanic;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primary),
                onPressed: () {
                  final navigator = Navigator.of(context);
                  if (navigator.canPop()) {
                    navigator.pop();
                  }
                },
              ),
            ),
            const SizedBox(height: 12),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  AppTextField(
                    controller: _login,
                    hint: 'Логин/телефон',
                    prefixIcon: Icons.person_outline,
                    keyboardType: TextInputType.phone,
                    focusNode: _loginFocus,
                  ),
                  const SizedBox(height: 12),
                  PasswordField(controller: _password, hint: 'Пароль'),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text.rich(
                      TextSpan(
                        text: 'Забыли пароль? ',
                        style: const TextStyle(color: AppColors.darkGray, fontSize: 14),
                        children: [
                          TextSpan(
                            text: 'Восстановить.',
                            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                            recognizer: TapGestureRecognizer()..onTap = () => Navigator.pushNamed(context, Routes.recoverAsk),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  BrandButton(text: 'ВОЙТИ', onPressed: _onLogin),
                ],
              ),
            ),
            const Spacer(),
            const Padding(
              padding: EdgeInsets.only(bottom: 24),
              child: BowlingMarketTitle(fontSize: 20),
            ),
          ],
        ),
      ),
    );
  }
}
