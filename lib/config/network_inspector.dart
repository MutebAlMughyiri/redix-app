// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:netoscope/netoscope.dart';

/// Whether this build keeps every call to the API in Netoscope, opened from its floating button (the owner, 18 and 19 Nov 2026, redix-app #119):
/// `NETWORK_INSPECTOR` in the build's config file, true in qa's and false in dev's and prod's, so any build turns it on or off in its own file.
const networkInspectorOn = bool.fromEnvironment('NETWORK_INSPECTOR');

/// Netoscope, which keeps the app's calls with passwords, tokens and cookies redacted. It turns itself off in a release build unless told, and
/// a qa build is one, so [networkInspectorOn] tells it.
final netoscope = Netoscope(config: const NetworkLoggerConfig(enabled: networkInspectorOn));

/// The app router's navigator, on which Netoscope's button opens its inspector.
final inspectorNavigatorKey = GlobalKey<NavigatorState>();

/// The client every call of the app goes through: Netoscope's, keeping each call, when [networkInspectorOn]; the default one otherwise. `main`
/// runs the app with it (package:http's runWithClient), so every call finds it without naming it.
http.Client callsClient() => networkInspectorOn ? netoscope.httpClient() : http.Client();

/// [child] under Netoscope's floating button when [networkInspectorOn]; [child] alone otherwise.
Widget withInspectorButton(Widget child) =>
    networkInspectorOn ? NetworkInspectorOverlay(netoscope: netoscope, navigatorKey: inspectorNavigatorKey, child: child) : child;
