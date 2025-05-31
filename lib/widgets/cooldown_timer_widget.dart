import 'dart:async';
import 'package:flutter/material.dart';
import 'package:questy/theme/app_theme.dart'; // For AppTheme.pixelBodyStyle

class CooldownTimerWidget extends StatefulWidget {
  final DateTime lastVerifiedTimestamp;
  final int cooldownDurationInMinutes;

  const CooldownTimerWidget({
    Key? key,
    required this.lastVerifiedTimestamp,
    required this.cooldownDurationInMinutes,
  }) : super(key: key);

  @override
  _CooldownTimerWidgetState createState() => _CooldownTimerWidgetState();
}

class _CooldownTimerWidgetState extends State<CooldownTimerWidget> {
  Timer? _timer;
  Duration _timeRemaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateTimeRemaining(); // Initial calculation
    // Start timer only if there's time remaining
    if (_timeRemaining > Duration.zero) {
      _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
        _updateTimeRemaining();
      });
    }
  }

  void _updateTimeRemaining() {
    if (!mounted) return; // Don't do anything if the widget is disposed

    final now = DateTime.now();
    final cooldownEndTime = widget.lastVerifiedTimestamp
        .add(Duration(minutes: widget.cooldownDurationInMinutes));

    if (now.isBefore(cooldownEndTime)) {
      setState(() {
        _timeRemaining = cooldownEndTime.difference(now);
      });
    } else {
      setState(() {
        _timeRemaining = Duration.zero;
      });
      _timer?.cancel(); // Stop timer if cooldown finished
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_timeRemaining <= Duration.zero) {
      // If cooldown is over, or was never applicable, don't show anything.
      // The parent widget should ideally not even render this if not on cooldown.
      return const SizedBox.shrink(); 
    }

    final hours = _timeRemaining.inHours;
    final minutes = _timeRemaining.inMinutes.remainder(60);
    final seconds = _timeRemaining.inSeconds.remainder(60);

    String cooldownText = 'Cooldown: ';
    if (hours > 0) cooldownText += '${hours}h ';
    // Show minutes if hours > 0 or minutes > 0
    if (hours > 0 || minutes > 0) cooldownText += '${minutes}m ';
    cooldownText += '${seconds}s';

    return Text(
      cooldownText,
      style: AppTheme.pixelBodyStyle.copyWith(
        fontSize: 12,
        color: Colors.orangeAccent,
        fontStyle: FontStyle.italic,
      ),
    );
  }
}
