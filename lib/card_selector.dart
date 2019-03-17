library card_selector;

import 'package:flutter/widgets.dart';

const defaultAnimationDuration = Duration(milliseconds: 200);

enum Position { left, right }

class CardSelector extends StatefulWidget {
  final List<Widget> cards;
  final ValueChanged<int> onChanged;
  final double mainCardWidth;
  final double mainCardHeight;
  final double mainCardPadding;
  final double cardsGap;
  final Duration cardAnimationDuration;
  final Position position;

  CardSelector({
    @required this.cards,
    this.onChanged,
    this.mainCardWidth = 240,
    this.mainCardHeight = 150,
    this.mainCardPadding = 0,
    this.cardsGap = 16,
    this.cardAnimationDuration = defaultAnimationDuration,
    this.position = Position.left,
  });

  @override
  _CardSelectorState createState() =>
      _CardSelectorState(cards.reversed.toList());
}

class _CardSelectorState extends State<CardSelector> {
  final List<Widget> _cards;

  var dropWidth = 0.0;
  var inDragTarget = false;
  var replacingCard = false;

  var initialCardListIndex = 0;

  _CardSelectorState(this._cards);

  scaleBetween(unscaledNum, minAllowed, maxAllowed, min, max) {
    return (maxAllowed - minAllowed) * (unscaledNum - min) / (max - min) +
        minAllowed;
  }

  @override
  Widget build(BuildContext context) {

    if (replacingCard) {
      initialCardListIndex ++;
      var last = _cards.removeLast();
      _cards.insert(0, last);

      setState(() {

      });

      Future.delayed(widget.cardAnimationDuration, () {


        if (widget.onChanged != null) {
          widget.onChanged(initialCardListIndex % widget.cards.length);
        }

        setState(() {
          inDragTarget = false;
          replacingCard = false;
        });
      });
    }

    var widgets = _cards.map((e)=>e).toList();
    widgets.add(Container(
      height: widget.mainCardHeight,
      width: dropWidth,
      child: DragTarget(
        builder: (context, List<String> candidateData, rejectedData) {
          return Container(
            height: widget.mainCardHeight,
            width: 100.0,
          );
        },
        onWillAccept: (data) {
          setState(() {
            inDragTarget = true;
          });

          return true;
        },
        onAccept: (data) {
          setState(() {
            replacingCard = true;
          });
        },
        onLeave: (data) {
          setState(() {
            inDragTarget = false;
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

          if (idx == widgets.length-1) return w; // return the drag target

          var lastCardIdx = widget.cards.length - (inDragTarget || replacingCard ? 2 : 1);

          var cardWidth =  widget.mainCardWidth;
          var cardHeight =  widget.mainCardHeight;
          if (idx < lastCardIdx) {
            var factor = scaleBetween(idx, 0.5, 1.0, 0, lastCardIdx);
            cardWidth = widget.mainCardWidth * factor;
            cardHeight = widget.mainCardHeight * factor;
          }

          var leftPadding = widget.mainCardPadding;
          if (idx < widgets.length - 2) {
            leftPadding =
                widget.mainCardPadding + widget.mainCardWidth - cardWidth +
                    (widget.cards.length - 1 - idx) * scaleBetween(
                        idx, widget.cardsGap / 2, widget.cardsGap, 0,
                        widget.cards.length - 1);
          }

          var opacity = 1.0;
          if (idx < lastCardIdx) {
            opacity = scaleBetween(idx, 0.0, 1.0, 0, lastCardIdx);
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
              setState(() => dropWidth = 64.0);
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
            duration: widget.cardAnimationDuration,
            curve: Curves.easeOut,
            top: (widget.mainCardHeight - cardHeight) / 2,
            left: leftPadding,
            child: AnimatedOpacity(
              opacity: opacity,
              curve: Curves.easeOut,
              duration: widget.cardAnimationDuration,
              child: idx == widgets.length - 2
                  ? draggableWidget
                  : AnimatedContainer(
                      duration: widget.cardAnimationDuration,
                      curve: Curves.easeOut,
                      width: cardWidth,
                      height: cardHeight,
                      child: w,
                    ),
            ),
          );
        }).toList(),
      ),
    );
  }
}