import 'package:blocs/blocs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Placeholder until step 3.3 puts the incident table here.
class IncidentsScreen extends StatelessWidget {
  const IncidentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Race Direction · Direkcija')),
      body: Center(
        child: BlocBuilder<IncidentsBloc, IncidentsState>(
          builder: (context, state) => switch (state) {
            IncidentsLoading() => const CircularProgressIndicator(),
            IncidentsFailure() => const Text('Incidenti nisu učitani.'),
            IncidentsLoaded(:final incidents) => Text('Učitano incidenata: ${incidents.length}'),
          },
        ),
      ),
    );
  }
}
