import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'models/atividade.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tzdata.initializeTimeZones();
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
    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        print('Notificação recebida/clicada: ${response.payload}');
        if (response.payload != null) {
          await _markActivityAsCompleted(response.payload!);
        }
      },
    );
    
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
    
    await Permission.notification.request();
    
    print('NotificationService inicializado com sucesso');
  }
  
  Future<bool> checkAndRequestExactAlarmPermission() async {
    if (await Permission.scheduleExactAlarm.isGranted) {
      return true;
    }
    
    final status = await Permission.scheduleExactAlarm.request();
    return status.isGranted;
  }

  Future<void> scheduleActivityNotification(Atividade a) async {
    print('Tentando agendar notificação para atividade: ${a.nome}');
    
    if (a.id == null) return;
    if (a.horario == null || a.horario!.isEmpty) return;
    final notificationStatus = await Permission.notification.request();
    print('Status permissão notificação: $notificationStatus');
    if (!notificationStatus.isGranted) {
      print('Permissão de notificação não concedida');
      return;
    }
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
    
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    
    print('Horário da atividade: ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}');
    print('Horário atual: ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}');

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
      print('Horário já passou hoje, agendando para amanhã');
    } else {
      print('Agendando para hoje');
    }

    print('Notificação programada para: $scheduled');
    print('Recorrente: ${a.recorrente}');

    final androidDetails = AndroidNotificationDetails(
      'atividades_channel',
      'Atividades',
      channelDescription: 'Lembretes de atividades',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
      ongoing: false,
      autoCancel: true,
    );
    final iosDetails = DarwinNotificationDetails();
    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _plugin.cancel(a.id!);

    await _plugin.zonedSchedule(
      a.id!,
      'Atividade: ${a.nome}',
      'É hora da sua atividade!',
      scheduled,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: a.recorrente ? DateTimeComponents.time : null,
      payload: a.id!.toString(),
    );
    
    print('Notificação agendada com ID ${a.id} para $scheduled');
  }

  Future<void> cancelNotificationForActivityId(int id) async {
    await _plugin.cancel(id);
  }
  Future<void> testNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'atividades_channel',
      'Atividades',
      channelDescription: 'Lembretes de atividades',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _plugin.show(
      999,
      'Teste de Notificação',
      'Se você está vendo isso, as notificações estão funcionando!',
      details,
    );
    print('Notificação de teste disparada!');
  }
  Future<void> rescheduleAllNotificationsForUser(int userId) async {
    try {
      print('Reagendando notificações para usuário $userId');
      
      final client = Supabase.instance.client;
      final results = await client
          .from('atividades')
          .select()
          .eq('id_usuario', userId)
          .eq('concluida', false)
          .not('horario', 'is', null);

      int count = 0;
      for (final r in results) {
        if (r is Map<String, dynamic>) {
          try {
            final atividade = Atividade.fromMap(r);
            if (atividade.horario != null && atividade.id != null) {
              await scheduleActivityNotification(atividade);
              count++;
            }
          } catch (e) {
            print('Erro ao reagendar atividade ${r['id']}: $e');
          }
        }
      }
      
      print('$count notificações reagendadas com sucesso');
    } catch (e) {
      print('Erro ao reagendar notificações: $e');
    }
  }

  Future<void> cancelAllNotifications() async {
    await _plugin.cancelAll();
    print('Todas as notificações foram canceladas');
  }

  Future<void> _markActivityAsCompleted(String activityIdStr) async {
    try {
      final activityId = int.tryParse(activityIdStr);
      if (activityId == null) return;

      print('Marcando atividade $activityId como concluída');
      
      final result = await Supabase.instance.client
          .from('atividades')
          .select('recorrente')
          .eq('id', activityId)
          .maybeSingle();
      
      if (result != null) {
        final isRecorrente = result['recorrente'] == true;
        
        if (!isRecorrente) {
          await Supabase.instance.client
              .from('atividades')
              .update({'concluida': true})
              .eq('id', activityId);
          
          await cancelNotificationForActivityId(activityId);
          print('Atividade $activityId marcada como concluída');
        } else {
          print('Atividade recorrente $activityId não será marcada como concluída');
        }
      }
    } catch (e) {
      print('Erro ao marcar atividade como concluída: $e');
    }
  }

  Future<void> markActivityAsCompleted(int activityId) async {
    await _markActivityAsCompleted(activityId.toString());
  }

  Future<void> resetRecurrentActivities(int userId) async {
    try {
      print('Verificando atividades recorrentes para reset...');
      
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final results = await Supabase.instance.client
          .from('atividades')
          .select()
          .eq('id_usuario', userId)
          .eq('recorrente', true)
          .eq('concluida', true)
          .not('data_conclusao', 'is', null);
      
      int resetCount = 0;
      for (final r in results) {
        try {
          final dataConclusa = DateTime.parse(r['data_conclusao'] as String);
          final dataConclusao = DateTime(dataConclusa.year, dataConclusa.month, dataConclusa.day);
          
          if (dataConclusao.isBefore(today)) {
            await Supabase.instance.client
                .from('atividades')
                .update({
                  'concluida': false,
                  'data_conclusao': null,
                })
                .eq('id', r['id']);
            
            final atividade = Atividade.fromMap(r);
            if (atividade.horario != null && atividade.id != null) {
              await scheduleActivityNotification(atividade);
            }
            
            resetCount++;
          }
        } catch (e) {
          print('Erro ao processar atividade ${r['id']}: $e');
        }
      }
      
      if (resetCount > 0) {
        print('$resetCount atividades recorrentes resetadas');
      }
    } catch (e) {
      print('Erro ao resetar atividades recorrentes: $e');
    }
  }
}
