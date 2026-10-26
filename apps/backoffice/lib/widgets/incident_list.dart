import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import '../text/labels.dart';
import 'scroll_into_view.dart';
import 'status_chip.dart';

const _rowHeight = 72.0;

/// The narrow-window replacement for the table: one line of text per incident,
/// the same selection.
class IncidentList extends StatefulWidget {
  const IncidentList({super.key, required this.incidents, required this.selectedId, required this.onSelected});

  final List<Incident> incidents;
  final IncidentId? selectedId;
  final ValueChanged<Incident> onSelected;

  @override
  State<IncidentList> createState() => _IncidentListState();
}

class _IncidentListState extends State<IncidentList> {
  final _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollToSelected();
  }

  @override
  void didUpdateWidget(IncidentList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedId != oldWidget.selectedId) _scrollToSelected();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _scrollToSelected() {
    final index = widget.incidents.indexWhere((incident) => incident.id == widget.selectedId);
    if (index == -1) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) scrollRowIntoView(_controller, index, _rowHeight);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _controller,
      itemExtent: _rowHeight,
      itemCount: widget.incidents.length,
      itemBuilder: (context, index) {
        final incident = widget.incidents[index];
        return IncidentListItem(
          key: ValueKey('row-${incident.id.value}'),
          incident: incident,
          selected: incident.id == widget.selectedId,
          onTap: () => widget.onSelected(incident),
        );
      },
    );
  }
}

class IncidentListItem extends StatelessWidget {
  const IncidentListItem({super.key, required this.incident, required this.selected, required this.onTap});

  final Incident incident;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected ? scheme.secondaryContainer : Colors.transparent,
      child: InkWell(
        canRequestFocus: false,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: selected ? scheme.primary : Colors.transparent, width: 4)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${incident.kind.label} · krivina ${incident.turn.value}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${riderLabel(incident.riderId)} · ${formatTime(incident.reportedAt)}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusChip(status: incident.status),
            ],
          ),
        ),
      ),
    );
  }
}
