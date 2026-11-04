import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/db.dart';
import 'ui/app_shell.dart';
import 'ui/style.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR');
  await AppDb.instance.database;
  runApp(const JuanRochaApp());
}

class JuanRochaApp extends StatelessWidget {
  const JuanRochaApp({super.key});
  @override Widget build(BuildContext context)=>MaterialApp(
    title:'Juan Rocha Boxe',debugShowCheckedModeBanner:false,
    theme:jrTheme(),home:const AppShell(),
  );
}
