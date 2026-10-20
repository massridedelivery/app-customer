import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:flutter/material.dart';

/// One stop of a coach-mark tour: the widget to spotlight (by its [target]
/// key) and what to say about it.
class CoachMarkStep {
  const CoachMarkStep({
    required this.target,
    required this.title,
    required this.body,
  });

  final GlobalKey target;
  final String title;
  final String body;
}

/// Shows a spotlight tour over the whole app (root overlay): the screen dims,
/// each step's target is cut out with a white ring, and a card with an arrow
/// explains it — "n / total", Skip, Next, and the last step's done label.
/// Steps whose target isn't laid out are skipped. [onFinish] runs once when
/// the tour ends, finished or skipped.
void showCoachMarks(
  BuildContext context, {
  required List<CoachMarkStep> steps,
  required String skipLabel,
  required String nextLabel,
  required String doneLabel,
  required VoidCallback onFinish,
}) {
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _CoachMarkOverlay(
      steps: steps,
      skipLabel: skipLabel,
      nextLabel: nextLabel,
      doneLabel: doneLabel,
      onClose: () {
        entry.remove();
        onFinish();
      },
    ),
  );
  Overlay.of(context, rootOverlay: true).insert(entry);
}

class _CoachMarkOverlay extends StatefulWidget {
  const _CoachMarkOverlay({
    required this.steps,
    required this.skipLabel,
    required this.nextLabel,
    required this.doneLabel,
    required this.onClose,
  });

  final List<CoachMarkStep> steps;
  final String skipLabel;
  final String nextLabel;
  final String doneLabel;
  final VoidCallback onClose;

  @override
  State<_CoachMarkOverlay> createState() => _CoachMarkOverlayState();
}

class _CoachMarkOverlayState extends State<_CoachMarkOverlay> {
  int _index = 0;
  bool _closed = false;

  bool get _isLast => _index == widget.steps.length - 1;

  void _close() {
    if (_closed) return;
    _closed = true;
    widget.onClose();
  }

  void _next() => _isLast ? _close() : setState(() => _index++);

  /// The step's target in screen coordinates, padded a little and kept 8px
  /// inside the screen (a full-width target would otherwise touch the edges),
  /// or null when it isn't on screen.
  Rect? _targetRect(CoachMarkStep step, Size screen) {
    final box = step.target.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize || !box.attached) return null;
    final padded = (box.localToGlobal(Offset.zero) & box.size).inflate(6);
    final visible = padded.intersect((Offset.zero & screen).deflate(8));
    return visible.isEmpty ? null : visible;
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.steps[_index];
    final size = MediaQuery.sizeOf(context);
    final rect = _targetRect(step, size);
    if (rect == null) {
      // Target not laid out (scrolled away / not built): move on.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_closed) _next();
      });
      return const SizedBox.shrink();
    }

    const margin = 16.0;
    final cardWidth = (size.width - margin * 2).clamp(0.0, 300.0);
    final below = size.height - rect.bottom >= 220;
    final cardLeft = (rect.center.dx - cardWidth / 2).clamp(
      margin,
      size.width - margin - cardWidth,
    );
    final arrowX = (rect.center.dx - cardLeft - 7).clamp(20.0, cardWidth - 34);
    final radius = (rect.height / 2).clamp(0.0, 22.0);

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // Tapping the dimmed area moves on, like the Next button.
          Positioned.fill(
            child: GestureDetector(
              onTap: _next,
              child: CustomPaint(
                painter: _SpotlightPainter(
                  hole: RRect.fromRectAndRadius(rect, Radius.circular(radius)),
                ),
              ),
            ),
          ),
          Positioned(
            left: cardLeft,
            width: cardWidth,
            top: below ? rect.bottom + 14 : null,
            bottom: below ? null : size.height - rect.top + 14,
            child: _CoachCard(
              arrowX: arrowX,
              arrowOnTop: below,
              counter: '${_index + 1} / ${widget.steps.length}',
              title: step.title,
              body: step.body,
              skipLabel: _isLast ? null : widget.skipLabel,
              actionLabel: _isLast ? widget.doneLabel : widget.nextLabel,
              onSkip: _close,
              onAction: _next,
            ),
          ),
        ],
      ),
    );
  }
}

/// Dims everything except [hole], which gets a white ring.
class _SpotlightPainter extends CustomPainter {
  _SpotlightPainter({required this.hole});

  final RRect hole;

  @override
  void paint(Canvas canvas, Size size) {
    final dim = Path.combine(
      PathOperation.difference,
      Path()..addRect(Offset.zero & size),
      Path()..addRRect(hole),
    );
    canvas.drawPath(dim, Paint()..color = const Color(0xAD0C0C12));
    canvas.drawRRect(
      hole,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(_SpotlightPainter old) => old.hole != hole;
}

class _CoachCard extends StatelessWidget {
  const _CoachCard({
    required this.arrowX,
    required this.arrowOnTop,
    required this.counter,
    required this.title,
    required this.body,
    required this.skipLabel,
    required this.actionLabel,
    required this.onSkip,
    required this.onAction,
  });

  final double arrowX;
  final bool arrowOnTop;
  final String counter;
  final String title;
  final String body;
  final String? skipLabel;
  final String actionLabel;
  final VoidCallback onSkip;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final arrow = Positioned(
      left: arrowX,
      top: arrowOnTop ? -7 : null,
      bottom: arrowOnTop ? null : -7,
      child: Transform.rotate(
        angle: 0.785398, // 45°
        child: Container(width: 14, height: 14, color: Colors.white),
      ),
    );
    return Stack(
      clipBehavior: Clip.none,
      children: [
        arrow,
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                counter,
                style: AppTypography.caption4.copyWith(
                  color: AppColors.semanticGrayNeutralFgMidOnWhite,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: AppTypography.label1.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(
                  body,
                  style: AppTypography.body2.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  if (skipLabel != null)
                    TextButton(
                      key: const Key('coachSkip'),
                      onPressed: onSkip,
                      style: TextButton.styleFrom(
                        foregroundColor:
                            AppColors.semanticGrayNeutralFgMidOnWhite,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                      ),
                      child: Text(skipLabel!, style: AppTypography.label2),
                    ),
                  const Spacer(),
                  FilledButton(
                    key: const Key('coachNext'),
                    onPressed: onAction,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                    ),
                    child: Text(
                      actionLabel,
                      style: AppTypography.label2.copyWith(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
