/// Shared layout metrics.
library;

/// Vertical space the floating bottom navigation occupies, measured from the
/// screen's bottom edge: the `bottom` gap (24) + the bar height (64) + a small
/// margin (16). Scrollable content on the main tab screens must reserve this
/// much bottom padding — PLUS `MediaQuery.viewPadding.bottom` for the device's
/// system-nav inset — so the last item (list tail, logout button, …) clears the
/// floating bar instead of hiding behind it. See [MainScreen] for the bar.
const double kFloatingNavReserve = 24 + 64 + 16; // = 104
