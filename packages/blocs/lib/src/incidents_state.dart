import 'package:domain/domain.dart';
import 'package:equatable/equatable.dart';

sealed class IncidentsState extends Equatable {
  const IncidentsState();
}

final class IncidentsLoading extends IncidentsState {
  const IncidentsLoading();

  @override
  List<Object?> get props => const [];
}

final class IncidentsFailure extends IncidentsState {
  const IncidentsFailure();

  @override
  List<Object?> get props => const [];
}

/// Where the report form currently stands.
enum SubmissionStatus { idle, inProgress, rejected, failed, succeeded }

final class IncidentsLoaded extends IncidentsState {
  const IncidentsLoaded({required this.incidents, this.submission = SubmissionStatus.idle, this.submissionError});

  /// Newest first.
  final List<Incident> incidents;
  final SubmissionStatus submission;

  /// Set only when [submission] is [SubmissionStatus.rejected].
  final DomainError? submissionError;

  bool get isEmpty => incidents.isEmpty;

  IncidentsLoaded withSubmission(SubmissionStatus status, {DomainError? error}) {
    return IncidentsLoaded(incidents: incidents, submission: status, submissionError: error);
  }

  @override
  List<Object?> get props => [incidents, submission, submissionError];
}
