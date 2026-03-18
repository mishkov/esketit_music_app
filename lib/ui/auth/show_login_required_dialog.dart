import 'package:flutter/material.dart';

Future<bool?> showLoginRequiredDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        // TODO: translate all this strings.
        title: const Text('Login required'),
        content: const Text('This feature requires login.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Go to login'),
          ),
        ],
      );
    },
  );
}
