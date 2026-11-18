// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:chucker_flutter/chucker_flutter.dart';
import 'package:http/http.dart' as http;

/// Whether this build keeps every call to the API for Chucker's screen, with its notice in the app (Muteb, 18 Nov 2026): `CHUCKER` in the
/// build's config file, true in qa's and false in dev's and prod's, so any build turns it on or off in its own file.
const chuckerOn = bool.fromEnvironment('CHUCKER');

/// The client every call of the app goes through: Chucker's, keeping each call, when [chuckerOn]; the default one otherwise. `main` runs the app
/// with it (package:http's runWithClient), so every call finds it without naming it.
http.Client callsClient() => chuckerOn ? ChuckerHttpClient(http.Client()) : http.Client();
