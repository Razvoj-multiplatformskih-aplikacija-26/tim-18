import 'dart:async';

import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../shortcuts.dart';
import '../text/error_messages.dart';
import '../widgets/debug_menu.dart';
import '../widgets/decision_bar.dart';
import '../widgets/filter_bar.dart';
import '../widgets/incident_list.dart';
import '../widgets/incident_panel.dart';
import '../widgets/incident_table.dart';
import '../widgets/shortcuts_dialog.dart';

/// Below this width the table becomes a list and the detail takes the whole
/// window instead of sitting next to it.
const _wideBreakpoint = 900.0;

class IncidentsScreen extends StatefulWidget {
  const IncidentsScreen({super.key});

  @override
  State<IncidentsScreen> createState() => _IncidentsScreenState();
}

class _IncidentsScreenState extends State<IncidentsScreen> {
  final _focus = FocusNode(debugLabel: 'incident-list');
  IncidentStage? _stage;
  Rider? _rider;

  /// The selection lives here, above the layout switch, so resizing the window
  /// never loses it.
  IncidentId? _selectedId;

  /// Narrow layout only: whether the detail covers the list. The wide layout
  /// shows the panel whenever something is selected.
  bool _detailOpen = false;

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  /// The list and the detail are different widgets, so after switching between
  /// them the focus is asked for again once they are built.
  void _refocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  void _select(Incident incident, {bool openDetail = false}) {
    setState(() {
      _selectedId = incident.id;
      if (openDetail) _detailOpen = true;
    });
    _refocus();
  }

  void _clearSelection() {
    setState(() {
      _selectedId = null;
      _detailOpen = false;
    });
    _refocus();
  }

  void _closeDetail() {
    setState(() => _detailOpen = false);
    _refocus();
  }

  /// Moves the selection by [delta] rows. Nothing selected yet: down starts at
  /// the first row, up at the last. The ends stop the selection.
  void _move(List<Incident> shown, int delta) {
    if (shown.isEmpty) return;
    final current = shown.indexWhere((incident) => incident.id == _selectedId);
    final next = current == -1 ? (delta > 0 ? 0 : shown.length - 1) : (current + delta).clamp(0, shown.length - 1);
    _select(shown[next]);
  }

  KeyEventResult _onKey(KeyEvent event, List<Incident> shown, {required bool narrow}) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowDown) {
      _move(shown, 1);
    } else if (key == LogicalKeyboardKey.arrowUp) {
      _move(shown, -1);
    } else if (key == LogicalKeyboardKey.home && shown.isNotEmpty) {
      _select(shown.first);
    } else if (key == LogicalKeyboardKey.end && shown.isNotEmpty) {
      _select(shown.last);
    } else if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter) {
      if (_selectedId == null) {
        _move(shown, 1);
      } else if (narrow) {
        setState(() => _detailOpen = true);
        _refocus();
      } else {
        return KeyEventResult.ignored;
      }
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  void _onSubmission(BuildContext context, IncidentsState state) {
    if (state is! IncidentsLoaded) return;
    final messenger = ScaffoldMessenger.of(context);
    switch (state.submission) {
      case SubmissionStatus.idle || SubmissionStatus.inProgress:
        break;
      case SubmissionStatus.succeeded:
        messenger.showSnackBar(const SnackBar(content: Text('Odluka je sačuvana.')));
      case SubmissionStatus.rejected:
        messenger.showSnackBar(SnackBar(content: Text(state.submissionError?.message ?? 'Odluka nije prihvaćena.')));
      case SubmissionStatus.failed:
        messenger.showSnackBar(const SnackBar(content: Text('Odluka nije sačuvana. Pokušajte ponovo.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<IncidentsBloc, IncidentsState>(
      listenWhen: (previous, current) =>
          current is IncidentsLoaded && (previous is! IncidentsLoaded || previous.submission != current.submission),
      listener: _onSubmission,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Race Direction · Direkcija'),
          actions: [
            IconButton(
              key: const Key('shortcuts-button'),
              tooltip: 'Prečice (F1)',
              icon: const Icon(Icons.keyboard_outlined),
              onPressed: () => unawaited(showShortcutsDialog(context)),
            ),
            const DebugMenu(),
          ],
        ),
        body: BlocBuilder<IncidentsBloc, IncidentsState>(
          builder: (context, state) => switch (state) {
            IncidentsLoading() => const Center(child: CircularProgressIndicator()),
            IncidentsFailure() => _ErrorView(
              onRetry: () => context.read<IncidentsBloc>().add(const IncidentsRequested()),
            ),
            IncidentsLoaded(isEmpty: true) => const _Message(
              icon: Icons.flag_outlined,
              text: 'Nema prijavljenih incidenata.',
            ),
            final IncidentsLoaded loaded => _workspace(loaded),
          },
        ),
      ),
    );
  }

  Widget _workspace(IncidentsLoaded loaded) {
    final incidents = loaded.incidents;
    final busy = loaded.submission == SubmissionStatus.inProgress;
    final shown = filterIncidents(incidents, stage: _stage, riderId: _rider?.id);
    final selected = incidents.where((incident) => incident.id == _selectedId).firstOrNull;

    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < _wideBreakpoint;
        final showDetail = narrow && selected != null && _detailOpen;

        final panel = selected == null
            ? null
            : IncidentPanel(
                incident: selected,
                all: incidents,
                busy: busy,
                onClose: narrow ? _closeDetail : _clearSelection,
                closeIcon: narrow ? Icons.arrow_back : Icons.close,
                closeTooltip: narrow ? 'Nazad' : 'Zatvori',
              );

        final Widget content;
        if (showDetail) {
          content = _keyboardArea(shown, narrow: narrow, child: panel!);
        } else {
          content = Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    FilterBar(
                      stage: _stage,
                      rider: _rider,
                      onStageChanged: (stage) => setState(() => _stage = stage),
                      onRiderChanged: (rider) => setState(() => _rider = rider),
                      shown: shown.length,
                      total: incidents.length,
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: _keyboardArea(
                        shown,
                        narrow: narrow,
                        child: shown.isEmpty
                            ? const _Message(
                                icon: Icons.filter_alt_off_outlined,
                                text: 'Nema incidenata za izabrane filtere.',
                              )
                            : narrow
                            ? IncidentList(
                                incidents: shown,
                                selectedId: _selectedId,
                                onSelected: (incident) => _select(incident, openDetail: true),
                              )
                            : IncidentTable(
                                incidents: shown,
                                selectedId: _selectedId,
                                onSelected: (incident) => _select(incident, openDetail: true),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              if (!narrow && panel != null) ...[const VerticalDivider(width: 1), SizedBox(width: 360, child: panel)],
            ],
          );
        }

        return CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.escape): showDetail ? _closeDetail : _clearSelection,
            const SingleActivator(LogicalKeyboardKey.f1): () => unawaited(showShortcutsDialog(context)),
            for (final decision in Decision.values)
              SingleActivator(decision.key): () {
                if (selected == null || busy || !decisionsFor(selected.status).contains(decision)) return;
                unawaited(runDecision(context, selected, decision));
              },
          },
          child: content,
        );
      },
    );
  }

  /// The part of the screen the arrow keys work on, with a ring while it has
  /// the focus.
  Widget _keyboardArea(List<Incident> shown, {required bool narrow, required Widget child}) {
    return Focus(
      focusNode: _focus,
      autofocus: true,
      onKeyEvent: (node, event) => _onKey(event, shown, narrow: narrow),
      child: ListenableBuilder(
        listenable: _focus,
        builder: (context, child) => DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(
              color: _focus.hasFocus ? Theme.of(context).colorScheme.primary : Colors.transparent,
              width: 2,
            ),
          ),
          child: child,
        ),
        child: child,
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [Icon(icon, size: 48), const SizedBox(height: 12), Text(text)],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            const Text('Incidenti nisu učitani.'),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Pokušaj ponovo')),
          ],
        ),
      ),
    );
  }
}
