import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../repositories/atividade_repository.dart';
import '../models/atividade.dart';
import '../services/notification_service.dart';

part 'atividade_controller.g.dart';

@riverpod
AtividadeRepository atividadeRepository(Ref ref) {
  return AtividadeRepository();
}

@riverpod
class AtividadeController extends _$AtividadeController {
  @override
  FutureOr<void> build() {}

  Future<List<Atividade>> load(int userId) async {
    final repo = ref.read(atividadeRepositoryProvider);
    final list = await repo.getByUser(userId);
    await NotificationService().resetRecurrentActivities(userId);
    await NotificationService().rescheduleAllNotificationsForUser(userId);
    return list;
  }
}
