import 'package:domain/domain.dart';
import 'package:flutter/services.dart';

/// One letter per decision of the direction.
extension DecisionKey on Decision {
  LogicalKeyboardKey get key => switch (this) {
    Decision.confirm => LogicalKeyboardKey.keyC,
    Decision.startReview => LogicalKeyboardKey.keyR,
    Decision.issuePenalty => LogicalKeyboardKey.keyK,
    Decision.dismiss => LogicalKeyboardKey.keyD,
  };

  String get keyLabel => switch (this) {
    Decision.confirm => 'C',
    Decision.startReview => 'R',
    Decision.issuePenalty => 'K',
    Decision.dismiss => 'D',
  };
}
