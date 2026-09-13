import 'package:flutter/foundation.dart';

// A plain top-level singleton, same pattern as themeController -- HomeScreen
// wraps Stations/Savings/My Bike in an IndexedStack specifically so each
// tab's fetched data survives switching away and back, but that means a
// swap logged from the Stations tab doesn't reach the other two tabs' own
// cached futures on its own. This is how they learn their cached data is
// stale and should be refetched, even while sitting inactive behind the
// IndexedStack.
class DataRefreshSignal extends ValueNotifier<int> {
  DataRefreshSignal() : super(0);

  void notifyChanged() => value++;
}

final dataRefreshSignal = DataRefreshSignal();
