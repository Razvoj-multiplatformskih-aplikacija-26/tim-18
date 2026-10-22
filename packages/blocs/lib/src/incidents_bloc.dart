import 'package:bloc/bloc.dart';
import 'package:domain/domain.dart';

import 'incident_repository.dart';
import 'incidents_event.dart';
import 'incidents_state.dart';

class IncidentsBloc extends Bloc<IncidentsEvent, IncidentsState> {
  IncidentsBloc({required this._repository, required this._user, required this._newId, DateTime Function()? now})
    : _now = now ?? DateTime.now,
      super(const IncidentsLoading()) {
    on<IncidentsRequested>(_onRequested);
    on<IncidentReported>(_onReported);
  }

  final IncidentRepository _repository;
  final User _user;
  final IncidentId Function() _newId;
  final DateTime Function() _now;

  Future<void> _onRequested(IncidentsRequested event, Emitter<IncidentsState> emit) async {
    if (state is! IncidentsLoading) emit(const IncidentsLoading());
    try {
      final incidents = await _repository.incidentsFor(_user);
      emit(IncidentsLoaded(incidents: _newestFirst(incidents)));
    } on RepositoryException {
      emit(const IncidentsFailure());
    }
  }

  Future<void> _onReported(IncidentReported event, Emitter<IncidentsState> emit) async {
    final current = state;
    if (current is! IncidentsLoaded || current.submission == SubmissionStatus.inProgress) return;

    final result = reportIncident(
      id: _newId(),
      by: _user,
      riderId: event.riderId,
      kind: event.kind,
      description: event.description,
      turn: event.turn,
      now: _now(),
    );

    final incident = result.valueOrNull;
    if (incident == null) {
      emit(current.withSubmission(SubmissionStatus.rejected, error: result.errorOrNull));
      return;
    }

    emit(current.withSubmission(SubmissionStatus.inProgress));
    try {
      final saved = await _repository.save(incident);
      emit(
        IncidentsLoaded(incidents: _newestFirst([saved, ...current.incidents]), submission: SubmissionStatus.succeeded),
      );
    } on RepositoryException {
      emit(current.withSubmission(SubmissionStatus.failed));
    }
  }

  static List<Incident> _newestFirst(List<Incident> incidents) {
    final sorted = [...incidents];
    sorted.sort((a, b) => b.reportedAt.compareTo(a.reportedAt));
    return sorted;
  }
}
