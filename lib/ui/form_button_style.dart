// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter/material.dart';

/// The one style of a form's full-width main button. It stays inside the form, so the keyboard never covers it (findings row 178, the owner, 9 Nov 2026).
const formButtonStyle = ButtonStyle(minimumSize: WidgetStatePropertyAll(Size.fromHeight(52)));
