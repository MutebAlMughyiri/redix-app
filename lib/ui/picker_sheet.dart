// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter/material.dart';

/// Opens a sheet of choices over [context], the same for every picker: it may fill the screen, keeps clear of the system bars and has a drag handle (redix-api #108).
Future<T?> showPickerSheet<T>(BuildContext context, WidgetBuilder builder) => showModalBottomSheet<T>(context: context, isScrollControlled: true, useSafeArea: true, showDragHandle: true, builder: builder);
