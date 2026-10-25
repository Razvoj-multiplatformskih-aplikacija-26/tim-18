import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import '../text/labels.dart';
import 'status_chip.dart';

/// Column widths as flex factors, shared by the header and every row.
const _flexTime = 1;
const _flexRider = 3;
const _flexKind = 3;
const _flexTurn = 1;
const _flexStatus = 2;

/// Every row has the same height, so the table can scroll to any row by its
/// index even when that row is not built yet.
const _rowHeight = 52.0;

class IncidentTable extends StatefulWidget {
  const IncidentTable({super.key, required this.incidents, required this.selectedId, required this.onSelected});

  final List<Incident> incidents;
  final IncidentId? selectedId;
  final ValueChanged<Incident> onSelected;

  @override
  State<IncidentTable> createState() => _IncidentTableState();
}

class _IncidentTableState extends State<IncidentTable> {
  final _controller = ScrollController();

  @override
  void didUpdateWidget(IncidentTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedId != oldWidget.selectedId) _scrollToSelected();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Keeps the selected row on screen when the keyboard moves the selection.
  void _scrollToSelected() {
    final index = widget.incidents.indexWhere((incident) => incident.id == widget.selectedId);
    if (index == -1) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_controller.hasClients) return;
      final position = _controller.position;
      final top = index * _rowHeight;
      final bottom = top + _rowHeight;
      if (top < position.pixels) {
        _controller.jumpTo(top);
      } else if (bottom > position.pixels + position.viewportDimension) {
        _controller.jumpTo(bottom - position.viewportDimension);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _HeaderRow(),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            controller: _controller,
            itemExtent: _rowHeight,
            itemCount: widget.incidents.length,
            itemBuilder: (context, index) {
              final incident = widget.incidents[index];
              return IncidentRow(
                key: ValueKey('row-${incident.id.value}'),
                incident: incident,
                selected: incident.id == widget.selectedId,
                onTap: () => widget.onSelected(incident),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: _flexTime,
            child: Text('Vreme', style: style),
          ),
          Expanded(
            flex: _flexRider,
            child: Text('Vozač', style: style),
          ),
          Expanded(
            flex: _flexKind,
            child: Text('Vrsta', style: style),
          ),
          Expanded(
            flex: _flexTurn,
            child: Text('Krivina', style: style),
          ),
          Expanded(
            flex: _flexStatus,
            child: Text('Stanje', style: style),
          ),
        ],
      ),
    );
  }
}

class IncidentRow extends StatelessWidget {
  const IncidentRow({super.key, required this.incident, required this.selected, required this.onTap});

  final Incident incident;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected ? scheme.secondaryContainer : Colors.transparent,
      child: InkWell(
        // The table as a whole takes the focus; the rows are not tab stops.
        canRequestFocus: false,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: selected ? scheme.primary : Colors.transparent, width: 4)),
          ),
          child: Row(
            children: [
              Expanded(flex: _flexTime, child: Text(formatTime(incident.reportedAt))),
              Expanded(
                flex: _flexRider,
                child: Text(riderLabel(incident.riderId), overflow: TextOverflow.ellipsis),
              ),
              Expanded(
                flex: _flexKind,
                child: Text(incident.kind.label, overflow: TextOverflow.ellipsis),
              ),
              Expanded(flex: _flexTurn, child: Text('${incident.turn.value}')),
              Expanded(
                flex: _flexStatus,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: StatusChip(status: incident.status),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
