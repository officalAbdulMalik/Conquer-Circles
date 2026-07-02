import 'package:flutter/material.dart';

Future<T?> showCustomAppDialog<T>({
  required BuildContext context,
  required Widget dialog,
  bool barrierDismissible = true,
  Color barrierColor = const Color(0x99000000),
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierColor: barrierColor,
    builder: (_) => dialog,
  );
}
