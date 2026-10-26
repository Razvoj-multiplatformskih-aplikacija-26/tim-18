import 'package:flutter/widgets.dart';

/// Scrolls [controller] just enough to bring row [index] fully into view, in a
/// list where every row is [rowHeight] tall. Works for rows that are not built.
void scrollRowIntoView(ScrollController controller, int index, double rowHeight) {
  if (!controller.hasClients) return;
  final position = controller.position;
  final top = index * rowHeight;
  final bottom = top + rowHeight;
  if (top < position.pixels) {
    controller.jumpTo(top);
  } else if (bottom > position.pixels + position.viewportDimension) {
    controller.jumpTo(bottom - position.viewportDimension);
  }
}
