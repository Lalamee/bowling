import 'package:flutter/material.dart';

abstract class MultiStepFormState<T extends StatefulWidget> extends State<T> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  int step = 0;

  bool validateCurrentStep() => formKey.currentState?.validate() ?? false;

  void nextStep() {
    if (validateCurrentStep()) setState(() => step++);
  }

  void prevStep() => setState(() => step--);
}
