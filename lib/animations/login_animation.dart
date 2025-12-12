import 'package:flutter/material.dart';

class HiWelcomeAnimation extends StatefulWidget {
  @override
  HiWelcomeAnimationState createState() => HiWelcomeAnimationState();
}

class HiWelcomeAnimationState extends State<HiWelcomeAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<double> moveX;
  late Animation<double> moveY;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    );

    moveX = Tween<double>(begin: -100, end: 800).animate(
      CurvedAnimation(parent: controller, curve: Curves.linear),
    );

    moveY = TweenSequence([
      TweenSequenceItem(
          tween: Tween(begin: -80.0, end: -240.0)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 1),
      TweenSequenceItem(
          tween: Tween(begin: -240.0, end: -80.0)
              .chain(CurveTween(curve: Curves.bounceOut)),
          weight: 1),
    ]).animate(controller);

    controller.repeat(reverse: false);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
            child: Stack(clipBehavior: Clip.none, children: [
          const Text(
            "Hi Welcome",
            style: TextStyle(
              fontSize: 80,
              fontWeight: FontWeight.bold,
              fontFamily: 'Sekuya',
            ),
          ),
          AnimatedBuilder(
              animation: controller,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(
                    moveX.value,
                    moveY.value,
                  ),
                  child: child,
                );
              },
              child: Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                  )))
        ])));
  }
}
