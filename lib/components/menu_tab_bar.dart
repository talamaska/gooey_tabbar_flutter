import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

class MenuTabBar extends StatefulWidget {
  final Widget child;
  final Color colorMenuIconDefault;
  final Color colorMenuIconActivated;
  final Color backgroundMenuIconDefault;
  final Color backgroundMenuIconActivated;
  final Color background;
  final List<IconButton> iconButtons;

  const MenuTabBar({
    Key? key,
    required this.child,
    this.background = Colors.blue,
    required this.iconButtons,
    this.colorMenuIconActivated = Colors.blue,
    this.colorMenuIconDefault = Colors.white,
    this.backgroundMenuIconActivated = Colors.white,
    this.backgroundMenuIconDefault = Colors.blue,
  })  : assert(iconButtons.length > 1 && iconButtons.length % 2 == 0),
        super(key: key);

  @override
  _MenuTabBar createState() => _MenuTabBar();
}

class _MenuTabBar extends State<MenuTabBar> with TickerProviderStateMixin {
  //-1 button is quiet
  //0 button is moving
  //1 button is activated
  late BehaviorSubject<int> _isActivated;
  late BehaviorSubject<double> _positionButton;
  late PublishSubject<double> _opacity;
  late AnimationController _animationControllerUp;
  late AnimationController _animationControllerDown;
  late AnimationController _animationControllerRotate;
  Animation<double>? _animationUp;
  Animation<double>? _animationDown;
  late Animation<double> _animationRotate;
  late VoidCallback _listenerDown;
  late VoidCallback _listenerUp;

  @override
  initState() {
    super.initState();

    _isActivated = BehaviorSubject<int>.seeded(-1);
    _opacity = PublishSubject<double>();
    _positionButton = BehaviorSubject<double>.seeded(10);

    _animationControllerUp = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animationControllerDown = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animationControllerRotate = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _animationRotate =
        Tween<double>(begin: 0, end: 2.3).animate(CurvedAnimation(
      parent: _animationControllerRotate,
      curve: Curves.ease,
    ));

    _listenerUp = () {
      _opacity.sink.add(1.0);
      _positionButton.sink.add(_animationUp?.value ?? 0.0);
    };
    _animationControllerUp.addListener(_listenerUp);

    _listenerDown = () {
      _positionButton.sink.add(_animationDown?.value ?? 0.0);
    };
    _animationControllerDown.addListener(_listenerDown);
  }

  List<Widget> _buildMenuIcons() {
    List<Widget> icons = <Widget>[];

    for (int i = 0; i < widget.iconButtons.length; i++) {
      if (i == widget.iconButtons.length / 2) {
        icons.add(SizedBox(
            width: MediaQuery.of(context).size.width /
                (widget.iconButtons.length + 1),
            height: 0));
      }
      icons.add(SizedBox(
          width: MediaQuery.of(context).size.width /
              (widget.iconButtons.length + 1),
          child: widget.iconButtons[i]));
    }

    return icons;
  }

  void _calculateOpacity(double dy) {
    double opacity = (MediaQuery.of(context).size.height - dy) /
        (MediaQuery.of(context).size.height * 0.3 - 60);
    if (opacity >= 0 && opacity <= 1) _opacity.sink.add(opacity);
  }

  void _updateButtonPosition(double dy) {
    double position = (MediaQuery.of(context).size.height - dy);

    if (position > 0) _positionButton.sink.add(position);

    _animationUp = Tween<double>(
            begin: position, end: MediaQuery.of(context).size.height * 0.7)
        .animate(CurvedAnimation(
            parent: _animationControllerUp, curve: Curves.ease));
    _animationDown = Tween<double>(begin: position, end: 10).animate(
        CurvedAnimation(parent: _animationControllerDown, curve: Curves.ease));
  }

  void _moveButtonDown() {
    _animationControllerDown.forward().whenComplete(() {
      _animationControllerDown.removeListener(_listenerDown);
      _animationControllerDown.reset();
      _animationDown?.addListener(_listenerDown);
    });

    _animationControllerRotate.reverse();
    _isActivated.sink.add(-1);
  }

  void _moveButtonUp() {
    _animationControllerUp.forward().whenComplete(() {
      _animationControllerUp.removeListener(_listenerUp);
      _animationControllerUp.reset();
      _animationUp?.addListener(_listenerUp);
    });

    _animationControllerRotate.forward();
    _isActivated.sink.add(1);
  }

  void _movementCancel(double dy) {
    if ((MediaQuery.of(context).size.height - dy) <
        MediaQuery.of(context).size.height * 0.3) {
      _moveButtonDown();
    } else {
      _moveButtonUp();
    }
  }

  void _finishedMovement(double dy) {
    if ((MediaQuery.of(context).size.height - dy).round() ==
        (MediaQuery.of(context).size.height * 0.3).round()) {
      _isActivated.sink.add(1);
    }
  }

  double? getPosition(double? data, Size mediaSize) {
    return (data ?? 0) >= mediaSize.height * 0.3
        ? (mediaSize.height * 0.3) - ((data ?? 0) - (mediaSize.height * 0.3))
        : data;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Stack(
          children: <Widget>[
            StreamBuilder<int>(
              stream: _isActivated.stream,
              builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
                return snapshot.data == -1
                    ? const SizedBox(height: 0, width: 0)
                    : StreamBuilder<double>(
                        initialData: 0.0,
                        stream: _opacity.stream,
                        builder: (BuildContext context,
                            AsyncSnapshot<double> snapshot) {
                          final Size mediaSize = MediaQuery.of(context).size;
                          return Opacity(
                            opacity: snapshot.data ?? 0.0,
                            child: StreamBuilder<double>(
                              initialData: 0.0,
                              stream: _positionButton.stream,
                              builder: (BuildContext context,
                                  AsyncSnapshot<double> snapshot) {
                                double? positon =
                                    getPosition(snapshot.data, mediaSize);
                                return ClipPath(
                                  clipper: ContainerClipper(positon ?? 0),
                                  child: Container(
                                    width: double.infinity,
                                    height: mediaSize.height,
                                    color: widget.background,
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      );
              },
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: _buildMenuIcons(),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Listener(
                    onPointerDown: (PointerDownEvent c) {
                      _isActivated.sink.add(0);
                    },
                    onPointerUp: (PointerUpEvent event) {
                      _movementCancel(event.position.dy);
                    },
                    onPointerMove: (PointerMoveEvent event) async {
                      _updateButtonPosition(event.position.dy);
                      _calculateOpacity(event.position.dy);
                      _finishedMovement(event.position.dy);
                    },
                    child: StreamBuilder<double>(
                      stream: _positionButton.stream,
                      initialData: 10.0,
                      builder: (BuildContext context,
                          AsyncSnapshot<double> snapshot) {
                        return Padding(
                          padding: EdgeInsets.only(bottom: snapshot.data ?? 10),
                          child: StreamBuilder<int>(
                            stream: _isActivated.stream,
                            builder: (BuildContext context,
                                AsyncSnapshot<int> snapshot) {
                              log('isActivated ${snapshot.data}');
                              return FloatingActionButton(
                                elevation: 0,
                                onPressed: () {
                                  _updateButtonPosition(0);
                                  // this should not happen
                                  // if (_isActivated.stream.value == 1) {
                                  //   _moveButtonDown();
                                  // } else {
                                  //   _moveButtonUp();
                                  // }
                                },
                                child: Transform.rotate(
                                  angle: _animationRotate.value,
                                  child: Icon(
                                    Icons.add,
                                    color: snapshot.data == -1
                                        ? widget.colorMenuIconDefault
                                        : widget.colorMenuIconActivated,
                                  ),
                                ),
                                backgroundColor: snapshot.data == -1
                                    ? widget.backgroundMenuIconDefault
                                    : widget.backgroundMenuIconActivated,
                              );
                            },
                          ),
                        );
                      },
                    ),
                  )
                ],
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: StreamBuilder<int>(
                stream: _isActivated.stream,
                builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
                  return snapshot.data == 1
                      ? Padding(
                          padding: const EdgeInsets.only(top: 0),
                          child: widget.child,
                        )
                      : const SizedBox(
                          width: 0,
                          height: 0,
                        );
                },
              ),
            )
          ],
        )
      ],
    );
  }

  @override
  void dispose() {
    _isActivated.close();
    _positionButton.close();
    _opacity.close();
    super.dispose();
  }
}

class MenuTabBarItem extends StatelessWidget {
  final Text label;
  final VoidCallback onTap;

  const MenuTabBarItem({
    Key? key,
    required this.label,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: label,
      onTap: onTap,
    );
  }
}

class ContainerClipper extends CustomClipper<Path> {
  final double dy;
  ContainerClipper(this.dy);

  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0.0, 0.0);
    path.lineTo(0.0, size.height);
    if (dy > -20) {
      path.quadraticBezierTo((size.width / 2) - 28, size.height - 20,
          size.width / 2, size.height - dy - 56);
    }
    path.lineTo(size.width / 2, size.height - (dy == 0 ? 0 : (dy + 56)));
    if (dy > -20) {
      path.quadraticBezierTo(
          (size.width / 2) + 28, size.height - 20, size.width, size.height);
    }
    path.lineTo(size.width, size.height);
    path.lineTo(size.width, 0);
    path.lineTo(0.0, 0.0);
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return true;
  }
}
