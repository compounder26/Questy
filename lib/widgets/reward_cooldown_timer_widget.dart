import 'dart:async';
import 'package:flutter/material.dart';
import 'package:questy/theme/app_theme.dart';

class RewardCooldownTimerWidget extends StatefulWidget {
  final DateTime? lastPurchaseTime;
  final int purchasePeriodHours;
  final int purchaseLimit;
  final int purchaseCount;

  const RewardCooldownTimerWidget({
    Key? key,
    required this.lastPurchaseTime,
    required this.purchasePeriodHours,
    required this.purchaseLimit,
    required this.purchaseCount,
  }) : super(key: key);

  @override
  _RewardCooldownTimerWidgetState createState() => _RewardCooldownTimerWidgetState();
}

class _RewardCooldownTimerWidgetState extends State<RewardCooldownTimerWidget> {
  Timer? _timer;
  Duration _timeRemaining = Duration.zero;
  bool _isAvailable = true;
  int _availablePurchases = 0;

  @override
  void initState() {
    super.initState();
    _updateAvailability();
    // Start timer if item is on cooldown
    if (!_isAvailable) {
      _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
        _updateAvailability();
      });
    }
  }

  void _updateAvailability() {
    if (!mounted) return;

    if (widget.lastPurchaseTime == null) {
      setState(() {
        _isAvailable = true;
        _availablePurchases = widget.purchaseLimit;
      });
      return;
    }

    final now = DateTime.now();
    final cooldownEndTime = widget.lastPurchaseTime!.add(
      Duration(hours: widget.purchasePeriodHours),
    );

    if (now.isAfter(cooldownEndTime)) {
      // Cooldown period has passed, reset purchase count
      setState(() {
        _isAvailable = true;
        _availablePurchases = widget.purchaseLimit;
      });
      _timer?.cancel();
    } else {
      // Still in cooldown
      setState(() {
        _isAvailable = false;
        _timeRemaining = cooldownEndTime.difference(now);
        _availablePurchases = widget.purchaseCount;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isAvailable) {
      return Text(
        '$_availablePurchases/${widget.purchaseLimit} available',
        style: AppTheme.pixelBodyStyle.copyWith(
          fontSize: 11,
          color: Colors.greenAccent,
        ),
      );
    }

    final hours = _timeRemaining.inHours.remainder(24);
    final minutes = _timeRemaining.inMinutes.remainder(60);
    final seconds = _timeRemaining.inSeconds.remainder(60);

    String cooldownText = 'Available in: ';
    if (hours > 0) cooldownText += '${hours}h ';
    if (minutes > 0 || hours > 0) cooldownText += '${minutes}m ';
    cooldownText += '${seconds}s';

    return Text(
      cooldownText,
      style: AppTheme.pixelBodyStyle.copyWith(
        fontSize: 11,
        color: Colors.orangeAccent,
        fontStyle: FontStyle.italic,
      ),
    );
  }
}
