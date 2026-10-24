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

  Future<void> expectStates(IncidentsBloc bloc, IncidentsEvent event, List<Matcher> states) async {
    final expectation = expectLater(bloc.stream, emitsInOrder(states));
    bloc.add(event);
    await expectation;
  }

  Future<IncidentsBloc> loadedBloc({User user = director}) async {
    final bloc = buildBloc(user);
    await expectStates(bloc, const IncidentsRequested(), [isA<IncidentsLoaded>()]);
    return bloc;
  }

  Matcher succeededWith(Matcher status) => isA<IncidentsLoaded>()
      .having((s) => s.submission, 'submission', SubmissionStatus.succeeded)
      .having((s) => s.incidents.single.status, 'status', status);

  Matcher rejectedWith(Object error) => isA<IncidentsLoaded>()
      .having((s) => s.submission, 'submission', SubmissionStatus.rejected)
      .having((s) => s.submissionError, 'error', error);

  final inProgress = isA<IncidentsLoaded>().having((s) => s.submission, 'submission', SubmissionStatus.inProgress);

  const id = IncidentId('i-1');

  setUp(() {
    repository = FakeIncidentRepository([incident('i-1')]);
  });

  group('the direction decides', () {
    test('confirms a reported incident', () async {
      final bloc = await loadedBloc();
      await expectStates(bloc, const IncidentConfirmed(id), [inProgress, succeededWith(isA<Confirmed>())]);
      expect(repository.updateCalls, 1);
    });

    test('takes an incident all the way to a penalty', () async {
      final bloc = await loadedBloc();
      await expectStates(bloc, const IncidentConfirmed(id), [inProgress, succeededWith(isA<Confirmed>())]);
      await expectStates(bloc, const IncidentReviewStarted(id), [inProgress, succeededWith(isA<UnderReview>())]);
      await expectStates(bloc, const IncidentPenalized(incidentId: id, kind: PenaltyKind.rideThrough, points: 2), [
        inProgress,
        succeededWith(
          isA<PenaltyIssued>()
              .having((s) => s.penalty.kind, 'kind', PenaltyKind.rideThrough)
              .having((s) => s.penalty.points, 'points', 2),
        ),
      ]);
    });

    test('dismisses an incident and keeps the trimmed reason', () async {
      final bloc = await loadedBloc();
      await expectStates(bloc, const IncidentDismissed(incidentId: id, reason: '  Duplikat.  '), [
        inProgress,
        succeededWith(isA<Dismissed>().having((s) => s.reason, 'reason', 'Duplikat.')),
      ]);
    });
  });

  group('the domain refuses', () {
    test('a penalty before the review', () async {
      final bloc = await loadedBloc();
      await expectStates(bloc, const IncidentPenalized(incidentId: id, kind: PenaltyKind.warning, points: 1), [
        rejectedWith(isA<InvalidTransition>()),
      ]);
      expect(repository.updateCalls, 0);
    });

    test('a dismissal without a reason', () async {
      final bloc = await loadedBloc();
      await expectStates(bloc, const IncidentDismissed(incidentId: id, reason: '   '), [
        rejectedWith(const ReasonRequired()),
      ]);
      expect(repository.updateCalls, 0);
    });

    test('penalty points outside the range', () async {
      final bloc = await loadedBloc();
      await expectStates(bloc, const IncidentPenalized(incidentId: id, kind: PenaltyKind.warning, points: 5), [
        rejectedWith(const InvalidPenaltyPoints(5)),
      ]);
    });

    test('a decision by a marshal', () async {
      final bloc = await loadedBloc(user: marshal);
      await expectStates(bloc, const IncidentConfirmed(id), [rejectedWith(const NotAllowed())]);
      expect(repository.updateCalls, 0);
    });

    test('an incident that does not exist', () async {
      final bloc = await loadedBloc();
      await expectStates(bloc, const IncidentConfirmed(IncidentId('nope')), [rejectedWith(const NotFound())]);
    });
  });

  test('a storage failure leaves the incident as it was', () async {
    final bloc = await loadedBloc();
    repository.failNext = true;

    await expectStates(bloc, const IncidentConfirmed(id), [
      inProgress,
      isA<IncidentsLoaded>()
          .having((s) => s.submission, 'submission', SubmissionStatus.failed)
          .having((s) => s.incidents.single.status, 'status', isA<Reported>()),
    ]);
  });
}
