import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'models/atividade.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tzdata.initializeTimeZones();
    // Definir fuso local (Brasil). Ajuste aqui se precisar de outro fuso.
    tz.Location localZone;
    try {
      localZone = tz.getLocation('America/Sao_Paulo');
    } catch (_) {
      localZone = tz.UTC;
    }
    tz.setLocalLocation(localZone);

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    const settings = InitializationSettings(android: android, iOS: ios);
    await _plugin.initialize(settings);
    
    // Create notification channel explicitly for Android
    const androidChannel = AndroidNotificationChannel(
      'atividades_channel',
      'Atividades',
      description: 'Lembretes de atividades',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );
    
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
    
    // Request notification permission for Android 13+
    await Permission.notification.request();
    
    print('NotificationService inicializado com sucesso');
  }
  
  Future<bool> checkAndRequestExactAlarmPermission() async {
    // Check if exact alarm permission is granted
    if (await Permission.scheduleExactAlarm.isGranted) {
      return true;
    }
    
    // Request permission (will open app settings on Android 12+)
    final status = await Permission.scheduleExactAlarm.request();
    return status.isGranted;
  }

  Future<void> scheduleActivityNotification(Atividade a) async {
    print('Tentando agendar notificação para atividade: ${a.nome}');
    
    if (a.id == null) return;
    if (a.horario == null || a.horario!.isEmpty) return;

    // Check and request notification permission (Android 13+)
    final notificationStatus = await Permission.notification.request();
    print('Status permissão notificação: $notificationStatus');
    if (!notificationStatus.isGranted) {
      print('Permissão de notificação não concedida');
      return;
    }

    // Check and request exact alarm permission
    final hasPermission = await checkAndRequestExactAlarmPermission();
    print('Status permissão alarme exato: $hasPermission');
    if (!hasPermission) {
      print('Permissão de alarme exato não concedida');
      return;
    }

    final parts = a.horario!.split(':');
    if (parts.length < 2) return;
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute)
      .subtract(const Duration(minutes: 15));
    if (scheduled.isBefore(now)) scheduled = scheduled.add(const Duration(days: 1));

    print('Horário agendado: $scheduled');
    print('Horário atual: $now');

    final androidDetails = AndroidNotificationDetails(
      'atividades_channel',
      'Atividades',
      channelDescription: 'Lembretes de atividades',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );
    final iosDetails = DarwinNotificationDetails();
    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _plugin.cancel(a.id!);

    await _plugin.zonedSchedule(
      a.id!,
      'Lembrete: ${a.nome}',
      'Começa em 15 minutos',
      scheduled,
      details,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: a.id!.toString(),
    );
    
    print('Notificação agendada com ID ${a.id} para $scheduled');
  }

  Future<void> cancelNotificationForActivityId(int id) async {
    await _plugin.cancel(id);
  }
}
