import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../core/routing/routes.dart';
import '../../../core/services/local_auth_storage.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/net_ui.dart';
import '../../../shared/widgets/titles/bowling_market_title.dart';
import '../data/auth_service.dart';
import '../validators/login_validator.dart';
import '../presentation/widgets/brand_button.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _submitted = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isNormalizing = false;
  String? _identifierServerError;

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _submitted = true;
      _identifierServerError = null;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);
    try {
      await AuthService.login(
        identifier: _loginController.text,
        password: _passwordController.text,
      );
      final role = await _cacheRole();
      if (!mounted) return;
      final destination = _routeForRole(role);
      Navigator.of(context).pushReplacementNamed(destination);
    } on AuthException catch (e) {
      switch (e.type) {
        case AuthErrorType.identifierInvalid:
        case AuthErrorType.invalidCredentials:
          setState(() {
            _identifierServerError = e.message;
          });
          _formKey.currentState!.validate();
          break;
        case AuthErrorType.network:
          showSnack(context, 'Нет соединения');
          break;
        case AuthErrorType.server:
          showSnack(context, e.message.isNotEmpty ? e.message : 'Ошибка сервера');
          break;
      }
    } catch (_) {
      showSnack(context, 'Ошибка сервера');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleIdentifierChanged(String value) {
    if (_identifierServerError != null) {
      setState(() => _identifierServerError = null);
    }
    if (_isNormalizing) return;
    final normalized = LoginValidator.normalize(value);
    if (normalized == null) {
      return;
    }
    final sanitized = normalized.value;
    final trimmed = value.trim();
    if (sanitized != trimmed) {
      _isNormalizing = true;
      _loginController.value = TextEditingValue(
        text: sanitized,
        selection: TextSelection.collapsed(offset: sanitized.length),
      );
      _isNormalizing = false;
    }
  }

  String? _validateIdentifier(String? value) {
    final baseError = LoginValidator.validate(value);
    if (baseError != null) {
      return baseError;
    }
    return _identifierServerError;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Введите пароль';
    }
    return null;
  }

  Future<String?> _cacheRole() async {
    final info = await AuthService.currentUser();
    if (info == null) return null;

    String? role;
    switch (info.accountTypeId) {
      case 1:
        role = 'mechanic';
        break;
      case 2:
        role = 'owner';
        break;
      case 3:
        role = 'manager';
        break;
      case 4:
        role = 'admin';
        break;
    }

    role ??= () {
      switch (info.roleId) {
        case 1:
          return 'mechanic';
        case 2:
          return 'manager';
        case 3:
          return 'owner';
        case 4:
          return 'admin';
        default:
          return null;
      }
    }();

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
    final autovalidateMode = _submitted
        ? AutovalidateMode.always
        : AutovalidateMode.onUserInteraction;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Form(
          key: _formKey,
          autovalidateMode: autovalidateMode,
          child: Column(
            children: [
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _loginController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        filled: true,
                        labelText: 'Логин (телефон или e-mail)',
                        prefixIcon: Icon(Icons.person_outline, color: AppColors.darkGray),
                      ),
                      onChanged: _handleIdentifierChanged,
                      validator: _validateIdentifier,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        filled: true,
                        labelText: 'Пароль',
                        prefixIcon: const Icon(Icons.lock_outline, color: AppColors.darkGray),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: AppColors.darkGray,
                          ),
                        ),
                      ),
                      validator: _validatePassword,
                    ),
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
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () => Navigator.pushNamed(context, Routes.recoverAsk),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    BrandButton(
                      text: 'ВОЙТИ',
                      onPressed: _onSubmit,
                      isLoading: _isLoading,
                    ),
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
      ),
    );
  }
}
