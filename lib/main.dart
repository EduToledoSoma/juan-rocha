import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/db.dart';
import 'ui/app_shell.dart';
import 'ui/style.dart';

// A interface e exibida antes de iniciar o banco, para evitar tela vazia.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  AppDb.configurePlatform();
  runApp(const JuanRochaApp());
}

class JuanRochaApp extends StatelessWidget {
  const JuanRochaApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Juan Rocha Boxe',
        debugShowCheckedModeBanner: false,
        theme: jrTheme(),
        home: const _StartupGate(),
      );
}

class _StartupGate extends StatefulWidget {
  const _StartupGate();

  @override
  State<_StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<_StartupGate> {
  late Future<void> _initialization;

  @override
  void initState() {
    super.initState();
    _initialization = _initialize();
  }

  Future<void> _initialize() async {
    await initializeDateFormatting('pt_BR');
    await AppDb.instance.database;
  }

  void _retry() {
    setState(() {
      _initialization = _initialize();
    });
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
        future: _initialization,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Scaffold(
              body: SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 52, color: brandGold),
                        const SizedBox(height: 14),
                        const Text(
                          'Falha ao iniciar o Juan Rocha Boxe',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Não foi possível preparar os dados locais. Tente novamente.',
                          textAlign: TextAlign.center,
                        ),
                        if (kDebugMode) ...[
                          const SizedBox(height: 16),
                          SelectableText(
                            'Diagnóstico: ${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 12, color: brandGoldLight),
                          ),
                        ],
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: _retry,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Tentar novamente'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(
              body: SafeArea(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.sports_mma, color: brandGold, size: 56),
                      SizedBox(height: 20),
                      Text('JUAN ROCHA BOXE',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold,
                              letterSpacing: 1, color: brandGoldLight)),
                      SizedBox(height: 14),
                      CircularProgressIndicator(color: brandGold),
                      SizedBox(height: 14),
                      Text('Preparando dados locais...'),
                    ],
                  ),
                ),
              ),
            );
          }
          return const AppShell();
        },
      );
}
