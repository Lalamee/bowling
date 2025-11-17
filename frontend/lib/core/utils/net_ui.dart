import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../api/api_core.dart';

void showSnack(BuildContext ctx, String msg, {bool success = false}) {
  ScaffoldMessenger.of(ctx).showSnackBar(
    SnackBar(
      content: Text(msg),
      backgroundColor: success ? Colors.green : Colors.red,
      duration: const Duration(seconds: 3),
    ),
  );
}

/// Показывает user-friendly ошибку из API
void showApiError(BuildContext ctx, dynamic error) {
  String message = 'Произошла ошибка';
  
  if (error is DioException && error.error is ApiException) {
    message = (error.error as ApiException).message;
  } else if (error is ApiException) {
    message = error.message;
  } else if (error is DioException) {
    message = error.message ?? 'Ошибка сети';
  } else if (error != null) {
    message = error.toString();
  }
  
  showSnack(ctx, message);
}

Future<T?> withLoader<T>(BuildContext ctx, Future<T> Function() task) async {
  showDialog(context: ctx, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
  try {
    return await task();
  } catch (e) {
    if (ctx.mounted) {
      Navigator.of(ctx, rootNavigator: true).pop();
      showApiError(ctx, e);
    }
    return null;
  } finally {
    if (ctx.mounted) {
      final navigator = Navigator.of(ctx, rootNavigator: true);
      if (navigator.canPop()) {
        navigator.pop();
      }
    }
  }
}

/// Выполняет асинхронную операцию с обработкой ошибок
Future<T?> handleApiCall<T>(
  BuildContext ctx,
  Future<T> Function() apiCall, {
  bool showLoader = true,
  String? successMessage,
}) async {
  try {
    final result = showLoader
        ? await withLoader(ctx, apiCall)
        : await apiCall();

    if (successMessage != null && ctx.mounted && result != null) {
      showSnack(ctx, successMessage, success: true);
    }

    return result;
  } catch (e) {
    if (ctx.mounted) {
      showApiError(ctx, e);
    }
    return null;
  }
}
