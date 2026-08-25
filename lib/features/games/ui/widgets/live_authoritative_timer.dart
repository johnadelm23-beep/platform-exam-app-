import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class LiveAuthoritativeTimer extends StatefulWidget {
  final DateTime endTime;
  final int totalSeconds;
  final VoidCallback onTimeUp;
  final bool isPaused;

  const LiveAuthoritativeTimer({
    super.key,
    required this.endTime,
    required this.totalSeconds,
    required this.onTimeUp,
    this.isPaused = false,
  });

  @override
  State<LiveAuthoritativeTimer> createState() => _LiveAuthoritativeTimerState();
}

class _LiveAuthoritativeTimerState extends State<LiveAuthoritativeTimer> {
  Timer? _ticker;
  int _secondsRemaining = 0;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _syncTimer();
    _ticker = Timer.periodic(const Duration(milliseconds: 200), (_) => _syncTimer());
  }

  void _syncTimer() {
    if (widget.isPaused) return;

    final now = DateTime.now();
    final difference = widget.endTime.difference(now).inMilliseconds;

    if (difference <= 0) {
      if (mounted && _secondsRemaining != 0) {
        setState(() => _secondsRemaining = 0);
      }
      if (!_completed) {
        _completed = true;
        _ticker?.cancel();
        widget.onTimeUp();
      }
    } else {
      final currentRemaining = (difference / 1000).ceil();
      if (mounted && currentRemaining != _secondsRemaining) {
        setState(() => _secondsRemaining = currentRemaining);
      }
    }
  }

  @override
  void didUpdateWidget(covariant LiveAuthoritativeTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.endTime != widget.endTime) {
      _completed = false;
      _syncTimer();
      if (_ticker == null || !_ticker!.isActive) {
        _ticker = Timer.periodic(const Duration(milliseconds: 200), (_) => _syncTimer());
      }
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: widget.isPaused ? Colors.red.withOpacity(0.25) : Colors.black.withOpacity(0.45),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: widget.isPaused ? Colors.redAccent : const Color(0xFFD97706),
          width: 2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            widget.isPaused ? Icons.pause_circle_filled : Icons.timer,
            color: widget.isPaused ? Colors.redAccent : const Color(0xFFD97706),
            size: 22.r,
          ),
          SizedBox(width: 8.w),
          Text(
            widget.isPaused ? "PAUSED ⏸" : "$_secondsRemaining s",
            style: GoogleFonts.cairo(
              fontSize: 22.sp,
              fontWeight: FontWeight.bold,
              color: widget.isPaused ? Colors.redAccent : const Color(0xFFD97706),
            ),
          ),
        ],
      ),
    );
  }
}
