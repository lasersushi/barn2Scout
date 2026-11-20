import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/ai_models.dart';

/// One AI write-up: a team summary, a match brief or a picklist review.
///
/// Nothing is requested until [generate] runs, and the UI calls it only from a
/// button, so opening a sheet never spends money or a daily generation.
class AiGenerateCubit extends Cubit<AiGenerateState> {
  AiGenerateCubit(this._start, {this.onRemaining})
      : super(const AiGenerateState());

  final Stream<AiEvent> Function() _start;

  /// Told the user's generations left today after each finished answer.
  final void Function(int? remaining)? onRemaining;
  StreamSubscription<AiEvent>? _sub;

  Future<void> generate() async {
    if (state.status == AiGenerateStatus.streaming) return;
    await _sub?.cancel();
    emit(const AiGenerateState(status: AiGenerateStatus.streaming));

    final buffer = StringBuffer();
    _sub = _start().listen(
      (event) {
        if (isClosed) return;
        switch (event) {
          case AiDelta(:final text):
            buffer.write(text);
            emit(state.copyWith(text: buffer.toString()));
          case AiDone():
            onRemaining?.call(event.remainingToday);
            emit(state.copyWith(
              status: AiGenerateStatus.done,
              cached: event.cached,
              truncated: event.truncated,
              remainingToday: event.remainingToday,
            ));
          case AiFailure(:final code, :final message):
            if (code == AiErrorCode.dailyLimit) onRemaining?.call(0);
            emit(state.copyWith(
              status: AiGenerateStatus.failed,
              errorCode: code,
              errorMessage: message,
            ));
        }
      },
      onError: (Object _) {
        if (isClosed) return;
        emit(state.copyWith(
          status: AiGenerateStatus.failed,
          errorCode: AiErrorCode.server,
          errorMessage: 'Something went wrong. Try again.',
        ));
      },
      onDone: () {
        // A stream that ends without done/failure was cut off.
        if (!isClosed && state.status == AiGenerateStatus.streaming) {
          emit(state.copyWith(
            status: AiGenerateStatus.failed,
            errorCode: AiErrorCode.offline,
            errorMessage: 'The connection dropped. Try again.',
          ));
        }
      },
    );
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}

enum AiGenerateStatus { idle, streaming, done, failed }

class AiGenerateState extends Equatable {
  const AiGenerateState({
    this.status = AiGenerateStatus.idle,
    this.text = '',
    this.cached = false,
    this.truncated = false,
    this.remainingToday,
    this.errorCode,
    this.errorMessage,
  });

  final AiGenerateStatus status;

  /// The answer so far; complete once [status] is done.
  final String text;
  final bool cached;
  final bool truncated;
  final int? remainingToday;
  final AiErrorCode? errorCode;
  final String? errorMessage;

  AiGenerateState copyWith({
    AiGenerateStatus? status,
    String? text,
    bool? cached,
    bool? truncated,
    int? remainingToday,
    AiErrorCode? errorCode,
    String? errorMessage,
  }) =>
      AiGenerateState(
        status: status ?? this.status,
        text: text ?? this.text,
        cached: cached ?? this.cached,
        truncated: truncated ?? this.truncated,
        remainingToday: remainingToday ?? this.remainingToday,
        errorCode: errorCode ?? this.errorCode,
        errorMessage: errorMessage ?? this.errorMessage,
      );

  @override
  List<Object?> get props =>
      [status, text, cached, truncated, remainingToday, errorCode, errorMessage];
}
