import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/models/capture_entry.dart';
import '../../../core/services/ble_source_provider.dart';
import '../../../core/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Session card — list item in the Lab session library
// ─────────────────────────────────────────────────────────────────────────────

class SessionCard extends StatelessWidget {
  final CaptureEntry entry;
  final VoidCallback? onTap;

  const SessionCard({super.key, required this.entry, this.onTap});

  @override
  Widget build(BuildContext context) {
    final session = entry.signalSession;
    if (session == null) return const SizedBox.shrink();

    final duration = session.duration;
    final durationStr = _formatDuration(duration);
    final dateStr = DateFormat('MMM d, yyyy · HH:mm').format(entry.timestamp);
    final channelStr =
        '${session.channelCount} ch · ${session.sampleRateHz.toInt()} Hz';

    // Parse title from first line of userNote (if set).
    final title = _parseTitle(entry.userNote);

    // User tags — plain strings (not system markers).
    final userTags = entry.tags
        .where((t) => !t.startsWith('artifact:') && !t.startsWith('event:'))
        .toList();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.tidePool,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppTheme.shimmer, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top row: source name + duration ────────────────────────
            Row(
              children: [
                Icon(Icons.sensors_rounded, size: 16, color: AppTheme.glow),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title ?? session.sourceName,
                    style: AppTheme.geist(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.moonbeam,
                      letterSpacing: -0.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  durationStr,
                  style: AppTheme.geist(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.glow,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // ── Sparkline preview ──────────────────────────────────────
            SizedBox(height: 32, child: _MiniSparkline(session: session)),

            // ── Tags ───────────────────────────────────────────────────
            if (userTags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: userTags.take(4).map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.glow.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                      border: Border.all(
                        color: AppTheme.glow.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      tag,
                      style: AppTheme.geist(
                        fontSize: 10,
                        color: AppTheme.glow.withValues(alpha: 0.8),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 8),

            // ── Bottom row: metadata ───────────────────────────────────
            Row(
              children: [
                Text(
                  dateStr,
                  style: AppTheme.geist(fontSize: 12, color: AppTheme.fog),
                ),
                const Spacer(),
                Text(
                  channelStr,
                  style: AppTheme.geist(fontSize: 12, color: AppTheme.mist),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }

  String? _parseTitle(String? userNote) {
    if (userNote == null || userNote.isEmpty) return null;
    final firstLine = userNote.split('\n').first.trim();
    return firstLine.isEmpty ? null : firstLine;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mini sparkline — shows first channel summary of the recording
// ─────────────────────────────────────────────────────────────────────────────

class _MiniSparkline extends StatelessWidget {
  final SignalSession session;
  const _MiniSparkline({required this.session});

  @override
  Widget build(BuildContext context) {
    if (session.samples.isEmpty) return const SizedBox.shrink();

    // Downsample to ~100 points for the sparkline
    final totalSamples = session.samples.length;
    final step = (totalSamples / 100).ceil().clamp(1, totalSamples);
    final points = <double>[];
    for (int i = 0; i < totalSamples; i += step) {
      final ch = session.samples[i].channels;
      if (ch.isNotEmpty) points.add(ch[0]);
    }

    if (points.isEmpty) return const SizedBox.shrink();

    return CustomPaint(
      size: const Size(double.infinity, 32),
      painter: _SparklinePainter(points: points),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> points;
  _SparklinePainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final min = points.reduce((a, b) => a < b ? a : b);
    final max = points.reduce((a, b) => a > b ? a : b);
    final range = max - min;
    if (range == 0) return;

    final paint = Paint()
      ..color = AppTheme.glow.withValues(alpha: 0.5)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final dx = size.width / (points.length - 1);
    final padding = 2.0;
    final usableHeight = size.height - padding * 2;

    for (int i = 0; i < points.length; i++) {
      final x = i * dx;
      final y = padding + usableHeight * (1 - (points[i] - min) / range);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter old) =>
      !identical(old.points, points);
}
