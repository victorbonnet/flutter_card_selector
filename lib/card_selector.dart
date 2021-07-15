library card_selector;

import 'package:flutter/widgets.dart';

const defaultAnimationDuration = 150;

enum Position { left, right }
enum CardSelectorState { idle, target, switching, targetBack, switchingBack }

/// A widget to select stacked widgets sliding left or right
class CardSelector extends StatefulWidget {
  final List<Widget> cards;
  final ValueChanged<int> onChanged;
  final double mainCardWidth;
  final double mainCardHeight;
  final double mainCardPadding;
  final double cardsGap;
  final int cardAnimationDurationMs;
  final double dropTargetWidth;
  final double lastCardSizeFactor;

  /// Creates a card selector widget.
  ///
  /// The [onChanged] is the callback to execute on card changed.
  ///
  /// The [mainCardWidth] is the width for the first element in the list.
  ///
  /// The [mainCardHeight] is the height for the first element in the list.
  ///
  /// The [mainCardPadding] left padding of the first element in the list.
  ///
  /// The [cardsGap] is the gap size between cards.
  ///
  /// The [cardAnimationDurationMs] is animation time in ms.
  ///
  /// The [dropTargetWidth] is the size of the drop targets.
  ///
  /// The [lastCardSizeFactor] is the factore of the last element to render
  /// compare to the first element.
  CardSelector({
    required this.cards,
    required this.onChanged,
    this.mainCardWidth = 240,
    this.mainCardHeight = 150,
    this.mainCardPadding = 0,
    this.cardsGap = 10,
    this.cardAnimationDurationMs = defaultAnimationDuration,
    this.dropTargetWidth = 64.0,
    this.lastCardSizeFactor = 0.6,
  });

  @override
  _CardSelectorState createState() {
    return _CardSelectorState(cards.reversed.map((w) {
      return Container(
        key: UniqueKey(),
        child: w,
      );
    }).toList());
  }
}

class _CardSelectorState extends State<CardSelector> {
  final List<Widget> _cards;

  var dropWidth = 50.0;
  var showLastCard = false;
  var disableCardPreviewAnim = false;
  var disableFirstCardAnimation = false;
  var disableLastCardAnimation = false;
  var disableDraggable = false;

  CardSelectorState csState = CardSelectorState.idle;

  var initialCardListIndex = 0;

  _CardSelectorState(this._cards);

  @override
  Widget build(BuildContext context) {
    if (csState == CardSelectorState.switching)
      nextCard();
    else if (csState == CardSelectorState.switchingBack) previousCard();

    var widgets = _cards.map((w) {
      var idx = _cards.indexOf(w);
      var cardPosition = widget.cards.length - 1 - idx;
      return cardWidget(w, cardPosition);
    }).toList();

    widgets.add(targetNext());
    widgets.add(targetPrevious());
    widgets.add(lastCardPreview());

    return SizedBox(
      width: double.infinity,
      height: widget.mainCardHeight,
      child: Stack(
        children: widgets,
      ),
    );
  }

  void updateState(CardSelectorState newState) {
    setState(() => csState = newState);
  }

  Widget lastCardPreview() {
    var lastCardAnimDuration =
        Duration(milliseconds: widget.cardAnimationDurationMs);
    var leftPaddingLastCard = -widget.mainCardWidth;
    if (csState == CardSelectorState.targetBack) {
      leftPaddingLastCard = leftPaddingLastCard + dropWidth * 2;
    } else if (csState == CardSelectorState.switchingBack) {
      leftPaddingLastCard = widget.mainCardPadding;
    } else if (disableCardPreviewAnim) {
      lastCardAnimDuration = Duration(milliseconds: 0);
      disableCardPreviewAnim = false;
    }
    return AnimatedPositioned(
      left: leftPaddingLastCard,
      duration: lastCardAnimDuration,
      child: Container(
        width: widget.mainCardWidth,
        height: widget.mainCardHeight,
        child: _cards[0],
      ),
    );
  }

  Widget targetNext() {
    return Container(
      height: widget.mainCardHeight,
      width: dropWidth,
      child: DragTarget(
        builder: (context, List<String?> candidateData, rejectedData) {
          return Container(
            height: widget.mainCardHeight,
            width: widget.dropTargetWidth,
          );
        },
        onWillAccept: (dynamic data) {
          updateState(CardSelectorState.target);
          return true;
        },
        onAccept: (dynamic data) {
          updateState(CardSelectorState.switching);
        },
        onLeave: (dynamic data) {
          updateState(CardSelectorState.idle);
        },
      ),
    );
  }

  Widget targetPrevious() {
    return Row(
      children: <Widget>[
        Expanded(child: Container()),
        Container(
          height: widget.mainCardHeight,
          width: dropWidth,
          child: DragTarget(
            builder: (context, List<String?> candidateData, rejectedData) {
              return Container(
                height: widget.mainCardHeight,
                width: widget.dropTargetWidth,
              );
            },
            onWillAccept: (dynamic data) {
              showLastCard = true;
              updateState(CardSelectorState.targetBack);
              return true;
            },
            onAccept: (dynamic data) {
              disableCardPreviewAnim = true;
              showLastCard = false;
              updateState(CardSelectorState.switchingBack);
            },
            onLeave: (dynamic data) {
              showLastCard = false;
              updateState(CardSelectorState.idle);
            },
          ),
        )
      ],
    );
  }

  Widget cardWidget(Widget w, int position) {
    var cardListLength = widget.cards.length;

    var positionFirstCard = 0;
    if (csState == CardSelectorState.target) positionFirstCard = 1;
    if (csState == CardSelectorState.targetBack) positionFirstCard = -1;
    if (csState == CardSelectorState.switchingBack) positionFirstCard = -1;

    var cardWidth = widget.mainCardWidth;
    var cardHeight = widget.mainCardHeight;
    if (position > positionFirstCard) {
      var idx = cardListLength - position + positionFirstCard;
      var factor =
          scaleBetween(idx, widget.lastCardSizeFactor, 1.0, 0, cardListLength);
      cardWidth = widget.mainCardWidth * factor;
      cardHeight = widget.mainCardHeight * factor;
    }

    var leftPadding = widget.mainCardPadding;
    if (position > positionFirstCard) {
      var idx = cardListLength - position + positionFirstCard;
      var leftPosAlignRight =
          widget.mainCardPadding + widget.mainCardWidth - cardWidth;
      leftPadding = leftPosAlignRight +
          (position - positionFirstCard) *
              scaleBetween(idx, widget.cardsGap / 2, widget.cardsGap, 0,
                  cardListLength - positionFirstCard);
    }

    double? opacity = 1.0;
    if (position > positionFirstCard) {
      opacity = scaleBetween(cardListLength - position, 0.0, opacity, 0,
          cardListLength - positionFirstCard);
    }

    var factorAnim = scaleBetween(position, 1, 2, 0, _cards.length - 1);
    var duration = (widget.cardAnimationDurationMs * factorAnim).round();
    var draggable = position == 0 && !disableDraggable;

    if (position == 0 && csState == CardSelectorState.target) {
      //place the card off the screen to improve the animation
      leftPadding = -widget.mainCardWidth;
    }

    if (position == 0 && disableFirstCardAnimation) {
      duration = 0;
      disableFirstCardAnimation = false;
    }

    if (position == _cards.length - 1 && disableLastCardAnimation) {
      duration = 0;
      disableLastCardAnimation = false;
    }

    return AnimatedPositioned(
      key: w.key,
      duration: Duration(milliseconds: (duration * 1.5).round()),
      curve: Curves.easeOut,
      top: (widget.mainCardHeight - cardHeight) / 2,
      left: leftPadding,
      child: AnimatedOpacity(
        opacity: opacity!,
        curve: Curves.easeOut,
        duration: Duration(milliseconds: duration),
        child: draggable
            ? Draggable(
                data: "card",
                axis: Axis.horizontal,
                feedback: Container(
                  width: cardWidth,
                  height: cardHeight,
                  child: w,
                ),
                childWhenDragging: AnimatedOpacity(
                  opacity: showLastCard ? 1 : 0,
                  duration: Duration(
                      milliseconds:
                          showLastCard ? widget.cardAnimationDurationMs : 0),
                  child: Container(
                    width: cardWidth,
                    height: cardHeight,
                    child: w,
                  ),
                ),
                child: Container(
                  width: cardWidth,
                  height: cardHeight,
                  child: w,
                ),
              )
            : AnimatedContainer(
                duration: Duration(milliseconds: duration),
                curve: Curves.easeOut,
                width: cardWidth,
                height: cardHeight,
                child: w,
              ),
      ),
    );
  }

  void nextCard() {
    initialCardListIndex++;
    var last = _cards.removeLast();
    _cards.insert(0, last);
    disableLastCardAnimation = true;
    disableDraggable = true;

    var duration = Duration(milliseconds: widget.cardAnimationDurationMs);
    Future.delayed(duration, () {
      disableDraggable = false;

      widget.onChanged(initialCardListIndex % widget.cards.length);

      updateState(CardSelectorState.idle);
    });
  }

  void previousCard() {
    disableDraggable = true;
    var duration = Duration(milliseconds: widget.cardAnimationDurationMs);
    Future.delayed(duration, () {
      disableDraggable = false;
      disableFirstCardAnimation = true;
      initialCardListIndex--;
      var first = _cards.removeAt(0);
      _cards.add(first);

      widget.onChanged(initialCardListIndex % widget.cards.length);

      updateState(CardSelectorState.idle);
    });
  }

  scaleBetween(unscaledNum, minAllowed, maxAllowed, min, max) {
    return (maxAllowed - minAllowed) * (unscaledNum - min) / (max - min) +
        minAllowed;
  }
}
