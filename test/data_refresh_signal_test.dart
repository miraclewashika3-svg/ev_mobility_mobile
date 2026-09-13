import 'package:flutter_test/flutter_test.dart';

import 'package:ev_mobility_mobile/services/data_refresh_signal.dart';

void main() {
  test('notifyChanged bumps the value and notifies listeners', () {
    final signal = DataRefreshSignal();
    var notifications = 0;
    signal.addListener(() => notifications++);

    signal.notifyChanged();
    signal.notifyChanged();

    expect(signal.value, 2);
    expect(notifications, 2);
  });

  test('a removed listener stops receiving notifications', () {
    final signal = DataRefreshSignal();
    var notifications = 0;
    void listener() => notifications++;

    signal.addListener(listener);
    signal.notifyChanged();
    signal.removeListener(listener);
    signal.notifyChanged();

    expect(notifications, 1);
  });
}
