import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../data/seed_data.dart';
import '../router.dart';
import '../text/error_messages.dart';
import '../text/labels.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _turnController = TextEditingController();
  final _descriptionController = TextEditingController();
  Rider? _rider;
  IncidentKind? _kind;

  @override
  void dispose() {
    _turnController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// The form only asks the domain whether the input is acceptable; the same
  /// parse functions decide again inside the BLoC.
  String? _validateTurn(String? input) {
    final turn = int.tryParse(input?.trim() ?? '');
    if (turn == null) return 'Unesite broj krivine.';
    return TurnNumber.parse(turn).errorOrNull?.message;
  }

  String? _validateDescription(String? input) {
    return IncidentDescription.parse(input ?? '').errorOrNull?.message;
  }

  void _submit() {
    final valid = _formKey.currentState?.validate() ?? false;
    final rider = _rider;
    final kind = _kind;
    final turn = int.tryParse(_turnController.text.trim());
    if (!valid || rider == null || kind == null || turn == null) return;

    context.read<IncidentsBloc>().add(
      IncidentReported(riderId: rider.id, kind: kind, description: _descriptionController.text, turn: turn),
    );
  }

  void _onSubmission(BuildContext context, IncidentsState state) {
    if (state is! IncidentsLoaded) return;
    final messenger = ScaffoldMessenger.of(context);
    switch (state.submission) {
      case SubmissionStatus.idle || SubmissionStatus.inProgress:
        break;
      case SubmissionStatus.succeeded:
        messenger.showSnackBar(const SnackBar(content: Text('Incident je prijavljen.')));
        context.goNamed(Routes.incidents);
      case SubmissionStatus.rejected:
        messenger.showSnackBar(SnackBar(content: Text(state.submissionError?.message ?? 'Prijava nije prihvaćena.')));
      case SubmissionStatus.failed:
        messenger.showSnackBar(const SnackBar(content: Text('Prijava nije sačuvana. Pokušajte ponovo.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final submitting = context.select<IncidentsBloc, bool>(
      (bloc) => switch (bloc.state) {
        IncidentsLoaded(:final submission) => submission == SubmissionStatus.inProgress,
        _ => false,
      },
    );

    return BlocListener<IncidentsBloc, IncidentsState>(
      listenWhen: (previous, current) =>
          current is IncidentsLoaded && (previous is! IncidentsLoaded || previous.submission != current.submission),
      listener: _onSubmission,
      child: Scaffold(
        appBar: AppBar(title: const Text('Prijava incidenta')),
        body: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              DropdownButtonFormField<Rider>(
                key: const Key('rider-field'),
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Vozač'),
                items: [for (final rider in riders) DropdownMenuItem(value: rider, child: Text(riderLabel(rider.id)))],
                onChanged: (rider) => _rider = rider,
                validator: (rider) => rider == null ? 'Izaberite vozača.' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<IncidentKind>(
                key: const Key('kind-field'),
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Vrsta incidenta'),
                items: [for (final kind in IncidentKind.values) DropdownMenuItem(value: kind, child: Text(kind.label))],
                onChanged: (kind) => _kind = kind,
                validator: (kind) => kind == null ? 'Izaberite vrstu incidenta.' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('turn-field'),
                controller: _turnController,
                decoration: InputDecoration(labelText: 'Krivina', hintText: '${TurnNumber.min}–${TurnNumber.max}'),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: _validateTurn,
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('description-field'),
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Opis',
                  helperText: 'Najviše ${IncidentDescription.maxLength} znakova',
                  alignLabelWithHint: true,
                ),
                minLines: 3,
                maxLines: 6,
                textCapitalization: TextCapitalization.sentences,
                validator: _validateDescription,
              ),
              const SizedBox(height: 24),
              FilledButton(
                key: const Key('submit-button'),
                onPressed: submitting ? null : _submit,
                child: submitting
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Pošalji prijavu'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
