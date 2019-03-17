library card_selector;

import 'package:flutter/widgets.dart';

const defaultAnimationDuration = 80;
const animDelayFactor = 1.3;

enum Position { left, right }

class CardSelector extends StatefulWidget {
  final List<Widget> cards;
  final ValueChanged<int> onChanged;
  final double mainCardWidth;
  final double mainCardHeight;
  final double mainCardPadding;
  final double cardsGap;
  final int cardAnimationDurationMs;
  final double dropTargetWidth;
  final Position position;

  CardSelector({
    @required this.cards,
    this.onChanged,
    this.mainCardWidth = 240,
    this.mainCardHeight = 150,
    this.mainCardPadding = 0,
    this.cardsGap = 12,
    this.cardAnimationDurationMs = defaultAnimationDuration,
    this.dropTargetWidth = 64.0,
    this.position = Position.left, //todo
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

  var dropWidth = 0.0;

  CardSelectorState csState = CardSelectorState.idle;

  var initialCardListIndex = 0;

  _CardSelectorState(this._cards);

  scaleBetween(unscaledNum, minAllowed, maxAllowed, min, max) {
    return (maxAllowed - minAllowed) * (unscaledNum - min) / (max - min) +
        minAllowed;
  }

  @override
  Widget build(BuildContext context) {
    if (csState == CardSelectorState.switching) {
      initialCardListIndex++;
      var last = _cards.removeLast();
      _cards.insert(0, last);

      var duration = Duration(milliseconds: widget.cardAnimationDurationMs);
      Future.delayed(duration, () {
        if (widget.onChanged != null) {
          widget.onChanged(initialCardListIndex % widget.cards.length);
        }

        setState(() {
          csState = CardSelectorState.idle;
        });
      });
    }

    var widgets = _cards.map((e) => e).toList();
    widgets.add(Container(
      height: widget.mainCardHeight,
      width: dropWidth,
      child: DragTarget(
        builder: (context, List<String> candidateData, rejectedData) {
          return Container(
            height: widget.mainCardHeight,
            width: widget.dropTargetWidth,
          );
        },
        onWillAccept: (data) {
          setState(() {
            csState = CardSelectorState.target;
          });

          return true;
        },
        onAccept: (data) {
          setState(() {
            csState = CardSelectorState.switching;
          });
        },
        onLeave: (data) {
          setState(() {
            csState = CardSelectorState.idle;
          });
        },
      ),
    ));

    return SizedBox(
      width: double.infinity,
      height: widget.mainCardHeight,
      child: Stack(
        children: widgets.map((w) {
          var idx = widgets.indexOf(w);
          if (idx == widgets.length - 1) return w; // return the drag target

          var cardPosition = widget.cards.length - 1 - idx;
          return cardWidget(w, cardPosition);
        }).toList(),
      ),
    );
  }

  Widget cardWidget(Widget w, int position) {
    var cardListLength = widget.cards.length;

    var positionFirstCard = 0;
    if (csState == CardSelectorState.target) positionFirstCard = 1;

    var cardWidth = widget.mainCardWidth;
    var cardHeight = widget.mainCardHeight;
    if (position > positionFirstCard) {
      var idx = cardListLength - position + positionFirstCard;
      var factor = scaleBetween(idx, 0.5, 1.0, 0, cardListLength);
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

    var opacity = 1.0;
    if (position > positionFirstCard) {
      opacity = scaleBetween(cardListLength - position - positionFirstCard, 0.0,
          1.0, 0, cardListLength - positionFirstCard);
    }

    var draggableWidget = Draggable(
      data: "card",
      axis: Axis.horizontal,
      feedback: Container(
        width: cardWidth,
        height: cardHeight,
        child: w,
      ),
      childWhenDragging: Container(),
      onDragStarted: () {
        setState(() => dropWidth = widget.dropTargetWidth);
      },
      onDragEnd: (details) {
        setState(() => dropWidth = 0.0);
      },
      child: Container(
        width: cardWidth,
        height: cardHeight,
        child: w,
      ),
    );

    return AnimatedPositioned(
      key: w.key,
      duration: Duration(
          milliseconds:
          (widget.cardAnimationDurationMs * position * animDelayFactor)
              .round()),
      curve: Curves.easeOut,
      top: (widget.mainCardHeight - cardHeight) / 2,
      left: leftPadding,
      child: AnimatedOpacity(
        opacity: opacity,
        curve: Curves.easeOut,
        duration:
        Duration(milliseconds: widget.cardAnimationDurationMs * position),
        child: position == 0
            ? draggableWidget
            : AnimatedContainer(
          duration: Duration(
              milliseconds: widget.cardAnimationDurationMs * position),
          curve: Curves.easeOut,
          width: cardWidth,
          height: cardHeight,
          child: w,
        ),
      ),
    );
  }
}

enum CardSelectorState { idle, target, switching }
