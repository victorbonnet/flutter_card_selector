library card_selector;

import 'package:flutter/widgets.dart';

const defaultAnimationDuration = Duration(milliseconds: 200);

enum Position { left, right }

class CardSelector extends StatefulWidget {
  final List<Widget> cards;
  final ValueChanged<int> onChanged;
  final double cardWidth;
  final double cardHeight;
  final Duration cardAnimationDuration;
  final Position position;

  CardSelector({
    @required this.cards,
    this.onChanged,
    this.cardWidth = 240,
    this.cardHeight = 150,
    this.cardAnimationDuration = defaultAnimationDuration,
    this.position = Position.left,
  });

  @override
  _CardSelectorState createState() => _CardSelectorState();
}

class _CardSelectorState extends State<CardSelector> {
  var dropWidth = 0.0;
  var secondCardDimRatio = 0.9;
  var thirdCardDimRatio = 0.8;
  var inDragTarget = false;
  var replacingCard = false;

  var index = 0;
  var firstCard;
  var secondCard;
  var thirdCard;

  @override
  void initState() {
    super.initState();

    firstCard = widget.cards[index];
    secondCard = widget.cards[index + 1];
    thirdCard = widget.cards[index + 2];
  }

  @override
  Widget build(BuildContext context) {
    var secondCardWidth = widget.cardWidth * secondCardDimRatio;
    var thirdCardWidth = widget.cardWidth * thirdCardDimRatio;
    var secondCardHeight = widget.cardHeight * secondCardDimRatio;
    var thirdCardHeight = widget.cardHeight * thirdCardDimRatio;

    if (replacingCard) {
      index++;

      Future.delayed(widget.cardAnimationDuration, () {
        firstCard = widget.cards[index % (widget.cards.length)];
        secondCard = widget.cards[(index + 1) % (widget.cards.length)];
        thirdCard = widget.cards[(index + 2) % (widget.cards.length)];

        if (widget.onChanged != null) {
          widget.onChanged(widget.cards.indexOf(firstCard));
        }

        setState(() {
          inDragTarget = false;
          secondCardDimRatio = 0.9;
          thirdCardDimRatio = 0.8;
          replacingCard = false;
        });
      });
    }

    return SizedBox(
      width: double.infinity,
      height: widget.cardHeight,
      child: Stack(
        children: <Widget>[
          AnimatedPositioned(
            duration: widget.cardAnimationDuration,
            curve: Curves.easeInOut,
            top: (widget.cardHeight - thirdCardHeight) / 2,
            left: replacingCard ? 28.0 : inDragTarget ? 44.0 : 68.0,
            child: AnimatedOpacity(
              duration: Duration(milliseconds: 100),
              opacity: 0.1,
              child: AnimatedContainer(
                duration: widget.cardAnimationDuration,
                curve: Curves.easeInOut,
                width: thirdCardWidth,
                height: thirdCardHeight,
                child: thirdCard,
              ),
            ),
          ),
          AnimatedPositioned(
            duration: widget.cardAnimationDuration,
            curve: Curves.easeInOut,
            top: (widget.cardHeight - secondCardHeight) / 2,
            left: replacingCard ? -16.0 : inDragTarget ? 0.0 : 28.0,
            child: AnimatedOpacity(
              duration: Duration(milliseconds: 100),
              opacity: 0.5,
              child: AnimatedContainer(
                duration: widget.cardAnimationDuration,
                curve: Curves.easeInOut,
                width: secondCardWidth,
                height: secondCardHeight,
                child: secondCard,
              ),
            ),
          ),
          replacingCard
              ? Container()
              : Positioned(
            left: -16.0,
            child: Draggable(
              data: "card",
              axis: Axis.horizontal,
              feedback: Container(
                width: widget.cardWidth,
                height: widget.cardHeight,
                child: firstCard,
              ),
              childWhenDragging: Container(),
              onDragStarted: () {
                setState(() {
                  dropWidth = 64.0;
                });
              },
              onDragEnd: (details) {
                setState(() {
                  dropWidth = 0.0;
                });
              },
              child: Container(
                width: widget.cardWidth,
                height: widget.cardHeight,
                child: firstCard,
              ),
            ),
          ),
          Container(
            height: widget.cardHeight,
            width: dropWidth,
            child: DragTarget(
              builder: (context, List<String> candidateData, rejectedData) {
                return Container(
                  height: widget.cardHeight,
                  width: 100.0,
                );
              },
              onWillAccept: (data) {
                setState(() {
                  inDragTarget = true;
                  secondCardDimRatio = 1;
                  thirdCardDimRatio = 0.9;
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
                  secondCardDimRatio = 0.9;
                  thirdCardDimRatio = 0.8;
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}