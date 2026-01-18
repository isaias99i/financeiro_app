import 'package:flutter/material.dart';

import 'aurora_background.dart';

// Scaffold padrao com fundo Aurora e padding correto.
class AuroraScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  const AuroraScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
  });

  // Monta o layout com background e area segura.
  @override
  Widget build(BuildContext context) {
    final mediaPadding = MediaQuery.of(context).padding;
    final topInset =
        (appBar?.preferredSize.height ?? 0.0) + mediaPadding.top;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: appBar,
      body: Stack(
        children: [
          const AuroraBackground(),
          Padding(
            padding: EdgeInsets.fromLTRB(0, topInset, 0, mediaPadding.bottom),
            child: body,
          ),
        ],
      ),
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
    );
  }
}
