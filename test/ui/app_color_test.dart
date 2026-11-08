import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/ui/app_color.dart';

/// One owner of every color (Muteb, 9 Nov 2026: "create one enum class color to store all colors of the app").
void main() {
  test('Muteb, 9 Nov 2026: every color the app shows is an AppColor; no other file picks a color of its own', () {
    final picksAColor = RegExp(r'colorScheme\.|Colors\.|Color\(0x');
    final strays = [
      for (final file in Directory('lib').listSync(recursive: true).whereType<File>())
        if (file.path.endsWith('.dart') && !file.path.endsWith('app_color.dart'))
          for (final (number, line) in file.readAsLinesSync().indexed)
            if (picksAColor.hasMatch(line)) '${file.path}:${number + 1}',
    ];

    expect(strays, isEmpty);
  });

  testWidgets('each color is the theme\'s, so a change of theme reaches every screen', (tester) async {
    late BuildContext context;
    await tester.pumpWidget(MaterialApp(theme: ThemeData(colorSchemeSeed: AppColor.seed), home: Builder(builder: (built) {
      context = built;
      return const SizedBox();
    })));
    final colors = Theme.of(context).colorScheme;

    expect((AppColor.refusal.of(context), AppColor.quiet.of(context), AppColor.frame.of(context), AppColor.activeSurface.of(context)), (colors.error, colors.onSurfaceVariant, colors.outlineVariant, colors.primaryContainer));
  });
}
