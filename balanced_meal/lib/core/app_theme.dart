import 'package:balanced_meal/core/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppTheme extends ConsumerWidget {
  final Widget child;

  const AppTheme({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    return MaterialApp(
      theme: theme,
      darkTheme: theme, // We're handling dark/light ourselves
      themeMode: ThemeMode.system, // Fallback if needed
      home: child,
    );
  }
}
