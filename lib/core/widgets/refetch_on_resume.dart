import 'package:flutter/widgets.dart';

/// Calls [onResume] whenever the app comes back to the foreground while this
/// widget is on screen — so lists cached in memory (trips, points, profile)
/// pick up server-side changes such as an admin clearing a test account's
/// history, without the user having to pull to refresh.
class RefetchOnResume extends StatefulWidget {
  const RefetchOnResume({
    super.key,
    required this.onResume,
    required this.child,
  });

  final VoidCallback onResume;
  final Widget child;

  @override
  State<RefetchOnResume> createState() => _RefetchOnResumeState();
}

class _RefetchOnResumeState extends State<RefetchOnResume> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: () => widget.onResume());
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
