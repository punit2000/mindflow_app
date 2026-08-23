/// Waits for a just-dismissed modal route (dialog / bottom sheet / pushed
/// route) to finish its exit animation before mutating providers.
///
/// Mutating Riverpod state in the same frame a route is being torn down can
/// trigger the Flutter framework assert `InheritedElement.debugDeactivated`
/// (`_dependents.isEmpty`), because the rebuild races with route teardown.
Future<void> waitForRouteExit() =>
    Future<void>.delayed(const Duration(milliseconds: 350));
