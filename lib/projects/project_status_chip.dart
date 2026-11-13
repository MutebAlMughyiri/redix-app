import 'package:flutter/material.dart';

import '../ui/app_color.dart';
import '../ui/part_keys.dart';
import '../words/words.dart';
import 'project.dart';

/// Where [project] stands, as a chip keyed [key], green while it is active and the signed-in user is not inactive in it, gray otherwise (redix-api #126 D2): the
/// project list and More info draw the same one (redix-api #108).
Chip projectStatusChip(BuildContext context, Project project, Key key) => Chip(
  key: key,
  label: Text(Words.of(context).text(project.status.wordKey), key: key.label),
  backgroundColor: project.status == ProjectStatus.active && !project.isInactive ? AppColor.activeSurface.of(context) : AppColor.mutedSurface.of(context),
  side: BorderSide.none,
  visualDensity: VisualDensity.compact,
);
