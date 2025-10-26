import 'package:flutter/widgets.dart';

// Global RouteObserver so pages can subscribe and get notified when they
// become visible again (useful to refresh history after returning from chat).
final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();
