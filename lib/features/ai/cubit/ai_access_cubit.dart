import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/ai_models.dart';
import '../../../data/repositories/ai_repository.dart';
import '../../../data/services/ai_service.dart';

/// Which AI features the signed-in user has (decides the AI tab's sub-tabs)
/// and how many generations they have left today. The server enforces the
/// same rules; this only shapes the UI.
class AiAccessCubit extends Cubit<AiAccessState> {
  AiAccessCubit(this._repo) : super(const AiAccessLoading());

  final AiRepository _repo;

  Future<void> load() async {
    emit(const AiAccessLoading());
    try {
      emit(AiAccessReady(await _repo.fetchAccess()));
    } on AiServiceException catch (e) {
      emit(AiAccessFailed(e.code, e.message));
    } on Object {
      emit(const AiAccessFailed(
          AiErrorCode.server, "Couldn't reach the AI service."));
    }
  }

  /// Applies the count a finished generation reported.
  void updateRemaining(int? remaining) {
    final s = state;
    if (s is AiAccessReady && !s.access.unlimited) {
      emit(AiAccessReady(s.access.withRemaining(remaining)));
    }
  }
}

sealed class AiAccessState extends Equatable {
  const AiAccessState();

  @override
  List<Object?> get props => [];
}

class AiAccessLoading extends AiAccessState {
  const AiAccessLoading();
}

class AiAccessReady extends AiAccessState {
  const AiAccessReady(this.access);
  final AiAccess access;

  @override
  List<Object?> get props => [access];
}

class AiAccessFailed extends AiAccessState {
  const AiAccessFailed(this.code, this.message);
  final AiErrorCode code;
  final String message;

  @override
  List<Object?> get props => [code, message];
}
