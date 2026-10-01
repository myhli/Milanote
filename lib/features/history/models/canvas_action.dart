import '../../cards/models/base_card.dart';
import '../../cards/models/connector_arrow.dart';

/// Base abstract class for atomic canvas actions in the Command Pattern.
/// Stored in the undo/redo stack with minimal memory footprint (<2MB for 50 steps).
abstract class CanvasAction {
  const CanvasAction();
}

/// Action when a new card is added to the canvas.
class AddCardAction extends CanvasAction {
  final BaseCard card;

  const AddCardAction(this.card);
}

/// Action when a card is removed from the canvas.
/// Also tracks any connector arrows that were attached and had to be removed.
class DeleteCardAction extends CanvasAction {
  final BaseCard card;
  final List<ConnectorArrow> attachedArrows;

  const DeleteCardAction({
    required this.card,
    this.attachedArrows = const [],
  });
}

/// Action when a card is moved to a new position.
class MoveCardAction extends CanvasAction {
  final String cardId;
  final double oldX;
  final double oldY;
  final double newX;
  final double newY;

  const MoveCardAction({
    required this.cardId,
    required this.oldX,
    required this.oldY,
    required this.newX,
    required this.newY,
  });
}

/// Action when a card is resized.
class ResizeCardAction extends CanvasAction {
  final String cardId;
  final double oldWidth;
  final double oldHeight;
  final double newWidth;
  final double newHeight;

  const ResizeCardAction({
    required this.cardId,
    required this.oldWidth,
    required this.oldHeight,
    required this.newWidth,
    required this.newHeight,
  });
}

/// Action when card properties/content are updated (e.g. text edit, color change, checklist toggle).
class UpdateCardAction extends CanvasAction {
  final BaseCard oldCard;
  final BaseCard newCard;

  const UpdateCardAction({
    required this.oldCard,
    required this.newCard,
  });
}

/// Action when card z-index is changed (e.g., bring to front).
class BringToFrontAction extends CanvasAction {
  final String cardId;
  final int oldZIndex;
  final int newZIndex;

  const BringToFrontAction({
    required this.cardId,
    required this.oldZIndex,
    required this.newZIndex,
  });
}

/// Action when a connector arrow is added.
class AddArrowAction extends CanvasAction {
  final ConnectorArrow arrow;

  const AddArrowAction(this.arrow);
}

/// Action when a connector arrow is deleted.
class DeleteArrowAction extends CanvasAction {
  final ConnectorArrow arrow;

  const DeleteArrowAction(this.arrow);
}

/// Action when a connector arrow properties (style, head, color, strokeWidth) are updated.
class UpdateArrowAction extends CanvasAction {
  final ConnectorArrow oldArrow;
  final ConnectorArrow newArrow;

  const UpdateArrowAction({
    required this.oldArrow,
    required this.newArrow,
  });
}

/// Composite action executing multiple actions as a single atomic step.
class BatchCanvasAction extends CanvasAction {
  final List<CanvasAction> actions;

  const BatchCanvasAction(this.actions);
}
