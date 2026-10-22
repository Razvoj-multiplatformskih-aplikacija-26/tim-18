import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:test/test.dart';

import 'fakes.dart';

void main() {
  late FakeIncidentRepository repository;
  var counter = 0;

  IncidentsBloc buildBloc({User user = marshal}) {
    final bloc = IncidentsBloc(
      repository: repository,
      user: user,
      newId: () => IncidentId('new-${counter++}'),
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

  setUp(() {
    counter = 0;
    repository = FakeIncidentRepository();
  });

  group('loading', () {
    test('starts in the loading state', () {
      expect(buildBloc().state, const IncidentsLoading());
    });

    test('emits the incidents newest first', () async {
      repository = FakeIncidentRepository([incident('i-1'), incident('i-2', minutes: 10)]);
      final bloc = buildBloc();
      await expectStates(bloc, const IncidentsRequested(), [
        isA<IncidentsLoaded>()
            .having((s) => s.incidents.map((i) => i.id.value), 'ids', ['i-2', 'i-1'])
            .having((s) => s.submission, 'submission', SubmissionStatus.idle),
      ]);
    });

    test('an empty repository gives an empty loaded state', () async {
      final bloc = buildBloc();
      await expectStates(bloc, const IncidentsRequested(), [
        isA<IncidentsLoaded>().having((s) => s.isEmpty, 'isEmpty', isTrue),
      ]);
    });

    test('a marshal sees only their own incidents, the direction sees all', () async {
      repository = FakeIncidentRepository([incident('i-1'), incident('i-2', reporterId: otherMarshal.id)]);

      final marshalBloc = buildBloc();
      await expectStates(marshalBloc, const IncidentsRequested(), [
        isA<IncidentsLoaded>().having((s) => s.incidents.length, 'length', 1),
      ]);

      final directorBloc = buildBloc(user: director);
      await expectStates(directorBloc, const IncidentsRequested(), [
        isA<IncidentsLoaded>().having((s) => s.incidents.length, 'length', 2),
      ]);
    });

    test('a failure can be retried', () async {
      repository = FakeIncidentRepository([incident('i-1')])..failNext = true;
      final bloc = buildBloc();

      await expectStates(bloc, const IncidentsRequested(), [isA<IncidentsFailure>()]);
      await expectStates(bloc, const IncidentsRequested(), [isA<IncidentsLoading>(), isA<IncidentsLoaded>()]);
    });
  });

  group('reporting', () {
    Future<IncidentsBloc> loadedBloc({User user = marshal}) async {
      final bloc = buildBloc(user: user);
      await expectStates(bloc, const IncidentsRequested(), [isA<IncidentsLoaded>()]);
      return bloc;
    }

    const validReport = IncidentReported(
      riderId: rider93,
      kind: IncidentKind.crash,
      description: 'Vozač je pao u krivini 5.',
      turn: 5,
    );

    test('a valid report is saved and shown first', () async {
      repository = FakeIncidentRepository([incident('i-1')]);
      final bloc = await loadedBloc();

      await expectStates(bloc, validReport, [
        isA<IncidentsLoaded>().having((s) => s.submission, 'submission', SubmissionStatus.inProgress),
        isA<IncidentsLoaded>()
            .having((s) => s.submission, 'submission', SubmissionStatus.succeeded)
            .having((s) => s.incidents.first.id, 'first id', const IncidentId('new-0'))
            .having((s) => s.incidents.length, 'length', 2),
      ]);
      expect(repository.saveCalls, 1);
    });

    test('a report that breaks a rule is rejected and never saved', () async {
      final bloc = await loadedBloc();

      await expectStates(
        bloc,
        const IncidentReported(riderId: rider93, kind: IncidentKind.crash, description: 'pad', turn: 5),
        [
          isA<IncidentsLoaded>()
              .having((s) => s.submission, 'submission', SubmissionStatus.rejected)
              .having((s) => s.submissionError, 'error', const DescriptionTooShort(3)),
        ],
      );
      expect(repository.saveCalls, 0);
    });

    test('the direction cannot report', () async {
      final bloc = await loadedBloc(user: director);

      await expectStates(bloc, validReport, [
        isA<IncidentsLoaded>().having((s) => s.submissionError, 'error', const NotAllowed()),
      ]);
      expect(repository.saveCalls, 0);
    });

    test('a storage failure keeps the list and reports the failure', () async {
      repository = FakeIncidentRepository([incident('i-1')]);
      final bloc = await loadedBloc();
      repository.failNext = true;

      await expectStates(bloc, validReport, [
        isA<IncidentsLoaded>().having((s) => s.submission, 'submission', SubmissionStatus.inProgress),
        isA<IncidentsLoaded>()
            .having((s) => s.submission, 'submission', SubmissionStatus.failed)
            .having((s) => s.incidents.length, 'length', 1),
      ]);
    });

    test('a report before the list is loaded is ignored', () async {
      final bloc = buildBloc();
      bloc.add(validReport);
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state, const IncidentsLoading());
      expect(repository.saveCalls, 0);
    });
  });
}
