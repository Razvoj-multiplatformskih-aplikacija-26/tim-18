import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:test/test.dart';

import 'fakes.dart';

void main() {
  late FakeIncidentRepository repository;

  Future<IncidentsBloc> loadedBloc() async {
    final bloc = IncidentsBloc(
      repository: repository,
      user: director,
      newId: () => const IncidentId('new'),
      now: () => raceStart.add(const Duration(minutes: 30)),
    );
    addTearDown(bloc.close);
    final loaded = expectLater(bloc.stream, emitsInOrder([isA<IncidentsLoaded>()]));
    bloc.add(const IncidentsRequested());
    await loaded;
    return bloc;
  }

  final inProgress = isA<IncidentsLoaded>().having((s) => s.submission, 'submission', SubmissionStatus.inProgress);

  setUp(() {
    repository = FakeIncidentRepository([incident('i-1')]);
  });

  test('a rule the server enforces is shown, then the list is loaded again', () async {
    final bloc = await loadedBloc();
    repository
      ..failNext = true
      ..failWith = const RepositoryException('refused', failure: RepositoryFailure.rejected, rule: NotAllowed());

    final expectation = expectLater(
      bloc.stream,
      emitsInOrder([
        inProgress,
        isA<IncidentsLoaded>()
            .having((s) => s.submission, 'submission', SubmissionStatus.rejected)
            .having((s) => s.submissionError, 'error', const NotAllowed()),
        isA<IncidentsLoading>(),
        isA<IncidentsLoaded>().having((s) => s.submission, 'submission', SubmissionStatus.idle),
      ]),
    );
    bloc.add(const IncidentConfirmed(IncidentId('i-1')));
    await expectation;
  });

  test('a refusal with a rule this client does not know is a plain failure, and the list is still reloaded', () async {
    final bloc = await loadedBloc();
    repository
      ..failNext = true
      ..failWith = const RepositoryException('refused', failure: RepositoryFailure.rejected);

    final expectation = expectLater(
      bloc.stream,
      emitsInOrder([
        inProgress,
        isA<IncidentsLoaded>().having((s) => s.submission, 'submission', SubmissionStatus.failed),
        isA<IncidentsLoading>(),
        isA<IncidentsLoaded>(),
      ]),
    );
    bloc.add(const IncidentConfirmed(IncidentId('i-1')));
    await expectation;
  });

  test('when the server is unreachable nothing is reloaded: the list stays as it was', () async {
    final bloc = await loadedBloc();
    repository
      ..failNext = true
      ..failWith = const RepositoryException('down', failure: RepositoryFailure.unavailable);

    final expectation = expectLater(
      bloc.stream,
      emitsInOrder([
        inProgress,
        isA<IncidentsLoaded>()
            .having((s) => s.submission, 'submission', SubmissionStatus.failed)
            .having((s) => s.incidents, 'incidents', hasLength(1)),
      ]),
    );
    bloc.add(const IncidentConfirmed(IncidentId('i-1')));
    await expectation;
  });
}
