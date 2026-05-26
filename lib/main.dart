import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'core/notifications/local_notifications.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await initializeDateFormatting('pt_BR');
  // Notificações locais (atualizações de pedido). Não bloqueia o boot se falhar.
  try {
    await LocalNotifications.instance.init();
  } catch (_) {}
  runApp(const ProviderScope(child: RaitoApp()));
}
