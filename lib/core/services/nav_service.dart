import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NavService {
  static final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

  static void go(String location) {
    final context = rootNavigatorKey.currentContext;
    if (context != null) {
      context.go(location);
    }
  }
}
