import 'package:flutter/material.dart';

import 'app_drawer.dart';

/// Спільна оболонка основних розділів застосунку.
/// Додає AppBar та burger menu.
class AppSectionScaffold extends StatelessWidget {
  final String title;
  final String currentRoute;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  const AppSectionScaffold({
    super.key,
    required this.title,
    required this.currentRoute,
    required this.body,
    this.actions,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(
        currentRoute: currentRoute,
      ),
      appBar: AppBar(
        title: Text(title),
        actions: actions,
      ),
      body: body,
      floatingActionButton: floatingActionButton,
    );
  }
}