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
    on<IncidentConfirmed>(
      (event, emit) => _decide(event.incidentId, (incident) => confirmIncident(incident, by: _user, now: _now()), emit),
    );
    on<IncidentReviewStarted>(
      (event, emit) => _decide(event.incidentId, (incident) => startReview(incident, by: _user, now: _now()), emit),
    );
    on<IncidentPenalized>((event, emit) => _decide(event.incidentId, (incident) => _penalize(incident, event), emit));
    on<IncidentDismissed>(
      (event, emit) => _decide(
        event.incidentId,
        (incident) => dismissIncident(incident, by: _user, now: _now(), reason: event.reason),
        emit,
      ),
    );
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

  /// Every decision of the direction goes through here: the domain function
  /// decides whether it is allowed, the repository stores the result.
  Future<void> _decide(
    IncidentId incidentId,
    Result<Incident> Function(Incident incident) decision,
    Emitter<IncidentsState> emit,
  ) async {
    final current = state;
    if (current is! IncidentsLoaded || current.submission == SubmissionStatus.inProgress) return;

    final incident = current.incidents.where((candidate) => candidate.id == incidentId).firstOrNull;
    if (incident == null) {
      emit(current.withSubmission(SubmissionStatus.rejected, error: const NotFound()));
      return;
    }

    final result = decision(incident);
    final decided = result.valueOrNull;
    if (decided == null) {
      emit(current.withSubmission(SubmissionStatus.rejected, error: result.errorOrNull));
      return;
    }

    emit(current.withSubmission(SubmissionStatus.inProgress));
    try {
      final saved = await _repository.update(decided);
      emit(
        IncidentsLoaded(
          incidents: _newestFirst([for (final stored in current.incidents) stored.id == saved.id ? saved : stored]),
          submission: SubmissionStatus.succeeded,
        ),
      );
    } on RepositoryException {
      emit(current.withSubmission(SubmissionStatus.failed));
    }
  }

  Result<Incident> _penalize(Incident incident, IncidentPenalized event) {
    final penalty = Penalty.parse(event.kind, event.points);
    final error = penalty.errorOrNull;
    if (error != null) return Failure(error);
    return issuePenalty(incident, by: _user, now: _now(), penalty: penalty.valueOrNull!);
  }

  static List<Incident> _newestFirst(List<Incident> incidents) {
    final sorted = [...incidents];
    sorted.sort((a, b) => b.reportedAt.compareTo(a.reportedAt));
    return sorted;
  }
}
