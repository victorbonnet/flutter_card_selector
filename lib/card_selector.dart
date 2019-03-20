library card_selector;

import 'package:flutter/widgets.dart';

const defaultAnimationDuration = 150;
const animDelayFactor = 1.05;

enum Position { left, right }
enum CardSelectorState { idle, target, switching, targetBack, switchingBack }

class CardSelector extends StatefulWidget {
  final List<Widget> cards;
  final ValueChanged<int> onChanged;
  final double mainCardWidth;
  final double mainCardHeight;
  final double mainCardPadding;
  final double cardsGap;
  final int cardAnimationDurationMs;
  final double dropTargetWidth;

  CardSelector({
    @required this.cards,
    this.onChanged,
    this.mainCardWidth = 240,
    this.mainCardHeight = 150,
    this.mainCardPadding = 0,
    this.cardsGap = 12,
    this.cardAnimationDurationMs = defaultAnimationDuration,
    this.dropTargetWidth = 64.0,
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
  var showLastCard = false;

  CardSelectorState csState = CardSelectorState.idle;

  var initialCardListIndex = 0;

  _CardSelectorState(this._cards);

  scaleBetween(unscaledNum, minAllowed, maxAllowed, min, max) {
    return (maxAllowed - minAllowed) * (unscaledNum - min) / (max - min) +
        minAllowed;
  }

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

  Widget lastCardPreview() {
    var lastCardAnimDuration =
        Duration(milliseconds: widget.cardAnimationDurationMs);
    var leftPaddingLastCard = -widget.mainCardWidth;
    if (csState == CardSelectorState.targetBack) {
      leftPaddingLastCard = leftPaddingLastCard + dropWidth * 2;
    } else if (csState == CardSelectorState.switchingBack) {
      leftPaddingLastCard = widget.mainCardPadding;
    } else {
      lastCardAnimDuration = Duration(milliseconds: 0);
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
            builder: (context, List<String> candidateData, rejectedData) {
              return Container(
                height: widget.mainCardHeight,
                width: widget.dropTargetWidth,
              );
            },
            onWillAccept: (data) {
              setState(() {
                showLastCard = true;
                csState = CardSelectorState.targetBack;
              });

              return true;
            },
            onAccept: (data) {
              setState(() {
                showLastCard = false;
                csState = CardSelectorState.switchingBack;
              });
            },
            onLeave: (data) {
              setState(() {
                showLastCard = false;
                csState = CardSelectorState.idle;
              });
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
      opacity = scaleBetween(cardListLength - position, 0.0, 1.0, 0,
          cardListLength - positionFirstCard);
    }

    var firstCardVisible = csState == CardSelectorState.targetBack;
    var draggableWidget = Draggable(
      data: "card",
      axis: Axis.horizontal,
      feedback: Container(
        width: cardWidth,
        height: cardHeight,
        child: w,
      ),
      childWhenDragging: AnimatedOpacity(
        opacity: firstCardVisible ? 1 : 0,
        duration: Duration(
            milliseconds:
                firstCardVisible ? widget.cardAnimationDurationMs : 0),
        child: Container(
          width: cardWidth,
          height: cardHeight,
          child: w,
        ),
      ),
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

    var duration =
        showLastCard && position == 0 ? 0 : widget.cardAnimationDurationMs;
    return AnimatedPositioned(
      key: w.key,
      duration: Duration(
          milliseconds: (duration * position * animDelayFactor).round()),
      curve: Curves.easeOut,
      top: (widget.mainCardHeight - cardHeight) / 2,
      left: leftPadding,
      child: AnimatedOpacity(
        opacity: opacity,
        curve: Curves.easeOut,
        duration: Duration(milliseconds: duration * position),
        child: position == 0
            ? draggableWidget
            : AnimatedContainer(
                duration: Duration(milliseconds: duration * position),
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

  void previousCard() {
    var duration = Duration(milliseconds: widget.cardAnimationDurationMs);
    Future.delayed(duration, () {
      initialCardListIndex--;
      var first = _cards.removeAt(0);
      _cards.add(first);

      if (widget.onChanged != null) {
        widget.onChanged(initialCardListIndex % widget.cards.length);
      }

      setState(() {
        csState = CardSelectorState.idle;
      });
    });
  }
}
