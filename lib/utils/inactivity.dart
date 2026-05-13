import 'dart:async';
import 'package:flutter/material.dart';

class InactivityWrapper extends StatefulWidget {
  final Widget child;

  const InactivityWrapper({super.key, required this.child});

  @override
  State<InactivityWrapper> createState() => _InactivityWrapperState();
}

class _InactivityWrapperState extends State<InactivityWrapper> {
  Timer? _timer;

  final int timeoutSeconds = 60;

  void _startTimer() {
    _timer?.cancel();

    _timer = Timer(Duration(seconds: timeoutSeconds), () {
      _lockApp();
    });
  }

  void _lockApp() {
    Navigator.pushNamedAndRemoveUntil(context, '/pin', (route) => false);
  }

  void _resetTimer([_]) {
    _startTimer();
  }

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,

      onTap: _resetTimer,
      onPanDown: _resetTimer,

      child: widget.child,
    );
  }
}
