import 'package:dio/dio.dart';

import '../../../../api/api_core.dart';
import '../../../../core/utils/net_ui.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/local_auth_storage.dart';
import '../../../../core/utils/phone_utils.dart';
import '../../../../core/authz/role_access.dart';
import '../../../../core/authz/role_context_resolver.dart';
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
      final ctx = await _cacheContext();
      if (!mounted) return;
      final destination = ctx?.access.homeRoute ?? Routes.profileMechanic;
      Navigator.of(context).pushNamedAndRemoveUntil(destination, (route) => false);
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

  Future<RoleAccountContext?> _cacheContext() async {
    final info = await AuthService.currentUser();
    if (info == null) return null;

    final resolved = RoleContextResolver.resolveFrom(info);

    if (resolved.role == RoleName.mechanic) {
      await LocalAuthStorage.clearOwnerState();
      await LocalAuthStorage.clearManagerState();
      await LocalAuthStorage.setMechanicRegistered(true);
    } else if (resolved.role == RoleName.clubOwner) {
      await LocalAuthStorage.clearMechanicState();
      await LocalAuthStorage.clearManagerState();
      await LocalAuthStorage.setOwnerRegistered(true);
    } else if (resolved.role == RoleName.headMechanic) {
      await LocalAuthStorage.clearMechanicState();
      await LocalAuthStorage.clearOwnerState();
    } else {
      await LocalAuthStorage.clearMechanicState();
      await LocalAuthStorage.clearOwnerState();
      await LocalAuthStorage.clearManagerState();
    }

    await LocalAuthStorage.setRegisteredRole(resolved.role.name);
    await LocalAuthStorage.setRegisteredAccountType(resolved.accountType?.name);
    return resolved;
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
