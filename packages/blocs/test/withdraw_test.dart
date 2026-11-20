import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:test/test.dart';

import 'fakes.dart';

void main() {
  late FakeIncidentRepository repository;

  IncidentsBloc buildBloc(User user) {
    final bloc = IncidentsBloc(
      repository: repository,
      user: user,
      newId: () => const IncidentId('new'),
      now: () => raceStart.add(const Duration(minutes: 30)),
    );
    addTearDown(bloc.close);
    return bloc;
  }

  Future<void> expectStates(IncidentsBloc bloc, IncidentsEvent event, List<Object> states) async {
    final expectation = expectLater(bloc.stream, emitsInOrder(states));
    bloc.add(event);
    await expectation;
  }

  Future<IncidentsBloc> loadedBloc(User user) async {
    final bloc = buildBloc(user);
    await expectStates(bloc, const IncidentsRequested(), [isA<IncidentsLoaded>()]);
    return bloc;
  }

  Matcher rejectedWith(Object error) => isA<IncidentsLoaded>()
      .having((s) => s.submission, 'submission', SubmissionStatus.rejected)
      .having((s) => s.submissionError, 'error', error);

  final inProgress = isA<IncidentsLoaded>().having((s) => s.submission, 'submission', SubmissionStatus.inProgress);

  setUp(() {
    repository = FakeIncidentRepository([
      incident('i-1'),
      incident(
        'i-2',
        status: Confirmed(by: director.id, at: raceStart),
      ),
    ]);
  });

  test('a marshal takes back a report of their own', () async {
    final bloc = await loadedBloc(marshal);
    await expectStates(bloc, const IncidentWithdrawn(IncidentId('i-1')), [
      inProgress,
      isA<IncidentsLoaded>().having((s) => s.submission, 'submission', SubmissionStatus.succeeded).having(
        (s) => s.incidents.map((i) => i.id.value),
        'ids',
        ['i-2'],
      ),
    ]);
    expect(repository.withdrawCalls, 1);
  });

  test('a report the direction has acted on stays, and the server is not asked', () async {
    final bloc = await loadedBloc(marshal);
    await expectStates(bloc, const IncidentWithdrawn(IncidentId('i-2')), [rejectedWith(const NotWithdrawable())]);
    expect(repository.withdrawCalls, 0);
  });

  test('the direction does not take reports back', () async {
    final bloc = await loadedBloc(director);
    await expectStates(bloc, const IncidentWithdrawn(IncidentId('i-1')), [rejectedWith(const NotAllowed())]);
    expect(repository.withdrawCalls, 0);
  });

  test('a report that is not in the list is not found', () async {
    final bloc = await loadedBloc(marshal);
    await expectStates(bloc, const IncidentWithdrawn(IncidentId('nope')), [rejectedWith(const NotFound())]);
  });
}
