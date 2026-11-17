import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/approvals/approvals_screen.dart';
import 'package:redix/auth/sign_in_screen.dart';
import 'package:redix/entries/add_entry_screen.dart';
import 'package:redix/entries/entries_screen.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/notifications/notifications_bell.dart';
import 'package:redix/notifications/notifications_screen.dart';
import 'package:redix/projects/new_project_screen.dart';
import 'package:redix/ui/api_list_body.dart';
import 'package:redix/ui/app_color.dart';
import 'package:redix/ui/app_theme.dart';
import 'package:redix/ui/part_keys.dart';
import 'package:redix/ui/screen_message.dart';
import 'package:redix/ui/section.dart';
import 'package:redix/ui/swipe_to_remove.dart';
import 'package:redix/words/language_switch.dart';

import '../app_harness.dart';

/// redix-app #96: every component sits in one border, never inside another's, with the theme's one gap; text starts on the language's side.
void main() {
  Finder cardOf(Key key) => find.ancestor(of: find.byKey(key), matching: find.byType(Card)).first;

  Card cardHolding(WidgetTester tester, Key key) => tester.widget<Card>(cardOf(key));

  /// T2, T3: no card sets a gap of its own, save the zero of a tile inside a panel, and no section holds a card beside its own.
  void expectOneLevelOfBorders(WidgetTester tester) {
    for (final card in tester.widgetList<Card>(find.byType(Card))) {
      expect(card.margin == null || card.margin == EdgeInsets.zero, isTrue, reason: '${card.key} sets its own gap ${card.margin}');
    }
    for (final section in tester.widgetList<Section>(find.byType(Section))) {
      expect(find.descendant(of: find.byWidget(section), matching: find.byType(Card)), findsOneWidget, reason: '${section.key} holds a card inside its border');
    }
  }

  Future<FakeApi> openNotifications(WidgetTester tester, {Locale locale = const Locale('en'), bool withOne = true}) async {
    final api = FakeApi()..addProject('غصون 6');
    if (withOne) {
      api.addNotification();
    }
    await pumpRedix(tester, api, locale: locale, stored: {'session': keptSession});
    await act(tester, api, () => tester.tap(find.byKey(NotificationsBell.buttonKey)));
    return api;
  }

  testWidgets('T1: sign-in holds the language in its border and the username and password in one section', (tester) async {
    await pumpRedix(tester, FakeApi());

    expect(find.byKey(SignInScreen.languageSectionKey), findsOneWidget);
    expect(cardHolding(tester, LanguageSwitch.choiceKey), same(tester.widget<Card>(find.byKey(SignInScreen.languageSectionKey.card))));
    expect(cardHolding(tester, SignInScreen.usernameKey), same(cardHolding(tester, SignInScreen.passwordKey)));
    expect(cardHolding(tester, SignInScreen.usernameKey), isNot(same(cardHolding(tester, LanguageSwitch.choiceKey))));
    expect(tester.widget<Text>(find.byKey(SignInScreen.forgotKey)).textAlign, isNull);
    expectOneLevelOfBorders(tester);
  });

  testWidgets('T1: a new project holds its own fields in one section, and the field that adds a unit in another under the unit rows', (tester) async {
    final api = FakeApi();
    await pumpRedix(tester, api);
    await tester.ensureVisible(find.byKey(SignInScreen.registerKey));
    await act(tester, api, () => tester.tap(find.byKey(SignInScreen.registerKey)));

    expect(cardHolding(tester, NewProjectScreen.nameKey), same(cardHolding(tester, NewProjectScreen.descriptionKey)));
    expect(cardHolding(tester, NewProjectScreen.nameKey), same(cardHolding(tester, NewProjectScreen.startDateKey)));
    expect(cardHolding(tester, NewProjectScreen.unitNameKey), isNot(same(cardHolding(tester, NewProjectScreen.nameKey))));
    await tester.ensureVisible(find.byKey(NewProjectScreen.managerNameKey));
    await tester.pumpAndSettle();
    expect(cardHolding(tester, NewProjectScreen.managerNameKey), same(cardHolding(tester, NewProjectScreen.passwordKey)));
    expectOneLevelOfBorders(tester);
  });

  testWidgets('T1, D2: the entries list holds its search, chips and count in one section above the rows', (tester) async {
    final api = FakeApi()..addProject('غصون 6');
    await openProject(tester, api);
    await scrollAndTap(tester, api, HomeScreen.entriesKey('project-0'));

    expect(cardHolding(tester, EntriesScreen.searchKey), same(cardHolding(tester, EntriesScreen.allKey)));
    expect(cardHolding(tester, EntriesScreen.searchKey), same(cardHolding(tester, EntriesScreen.foundKey)));
    expectOneLevelOfBorders(tester);
  });

  testWidgets('T1, D2: Approvals holds its filter chips in one section, and each waiting entry keeps its own card', (tester) async {
    final api = FakeApi()..addProject('غصون 6', permissions: managerAndFinance);
    api.addPending();
    await openProject(tester, api);
    await scrollAndTap(tester, api, HomeScreen.approvalsKey('project-0'));

    expect(cardHolding(tester, ApprovalsScreen.allKey), same(cardHolding(tester, ApprovalsScreen.purchasesKey)));
    expect(find.byKey(ApprovalsScreen.filtersKey), findsOneWidget);
    expectOneLevelOfBorders(tester);
  });

  testWidgets('T1: each notification sits in its own card', (tester) async {
    await openNotifications(tester);

    expect(find.byKey(NotificationsScreen.rowKey('notification-0').card), findsOneWidget);
    expect(cardHolding(tester, NotificationsScreen.rowKey('notification-0')), isNotNull);
    expectOneLevelOfBorders(tester);
  });

  testWidgets('T1: Add entry holds the file and its ways to take it in one invoice section, ahead of the form sections', (tester) async {
    final api = FakeApi()..addProject('غصون 6', permissions: field, units: ['الفلة الغربية']);
    await openProject(tester, api);
    await act(tester, api, () => tester.tap(find.byKey(HomeScreen.addEntryKey('project-0'))));

    expect(cardHolding(tester, AddEntryScreen.cameraKey), same(cardHolding(tester, AddEntryScreen.filesKey)));
    expect(find.byKey(AddEntryScreen.invoiceSectionKey), findsOneWidget);
    expect(tester.getTopLeft(find.byKey(AddEntryScreen.invoiceSectionKey)).dy, lessThan(tester.getTopLeft(find.byKey(AddEntryScreen.forSectionKey)).dy));
    expectOneLevelOfBorders(tester);
  });

  for (final (language, rightToLeft) in [('ar', true), ('en', false)]) {
    testWidgets('T4, T5, D6: in $language the empty list says so at the top, on the language\'s side, not mid-screen', (tester) async {
      await openNotifications(tester, locale: Locale(language), withOne: false);

      final words = tester.getRect(find.byKey(ApiListBody.emptyKey));
      final screen = tester.getSize(find.byType(Scaffold).first);
      if (rightToLeft) {
        expect(words.right, greaterThan(screen.width - 40));
      } else {
        expect(words.left, lessThan(40));
      }
      expect(words.top, lessThan(screen.height / 4));
    });
  }

  testWidgets('T6: the spinner of a list still being read stays centered', (tester) async {
    late BuildContext context;
    await tester.pumpWidget(MaterialApp(theme: appThemeOf(Brightness.light), home: Builder(builder: (built) {
      context = built;
      return const Scaffold(body: Center(child: CircularProgressIndicator(key: ApiListBody.loadingKey)));
    })));

    final spinner = tester.getCenter(find.byKey(ApiListBody.loadingKey));
    expect(spinner.dx, closeTo(MediaQuery.sizeOf(context).width / 2, 1));
  });

  for (final (language, rightToLeft) in [('ar', true), ('en', false)]) {
    testWidgets('T4: in $language a screen\'s message and its action start on the language\'s side', (tester) async {
      const words = Key('test.words');
      const action = Key('test.action');
      await tester.pumpWidget(MaterialApp(
        theme: appThemeOf(Brightness.light),
        home: Directionality(
          textDirection: rightToLeft ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(body: ScreenMessage('Nothing yet.', textKey: words, action: OutlinedButton(key: action, onPressed: () {}, child: const Text('Retry')))),
        ),
      ));

      final width = tester.getSize(find.byType(Scaffold)).width;
      for (final key in [words, action]) {
        final rect = tester.getRect(find.byKey(key));
        expect(rightToLeft ? rect.right : rect.left, closeTo(rightToLeft ? width - 24 : 24, 1), reason: '$key');
      }
    });
  }

  testWidgets('T7, D10: on iPhone a title with one action starts on the language\'s side, where Flutter alone would center it', (tester) async {
    const title = Key('test.title');
    Future<double> titleLeftWith(ThemeData theme) async {
      await tester.pumpWidget(MaterialApp(
        theme: theme.copyWith(platform: TargetPlatform.iOS),
        home: Scaffold(appBar: AppBar(title: const Text('Title', key: title), actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.add))])),
      ));
      await tester.pumpAndSettle();
      return tester.getTopLeft(find.byKey(title)).dx;
    }

    expect(await titleLeftWith(appThemeOf(Brightness.light)), lessThan(100));
    expect(await titleLeftWith(ThemeData()), greaterThan(100));
  });

  for (final brightness in Brightness.values) {
    testWidgets('T8: in ${brightness.name} a section is framed in AppColor.frame, and a status card keeps its own color', (tester) async {
      late BuildContext context;
      const section = Key('test.section');
      const row = Key('test.row');
      const statusSide = BorderSide(color: Colors.orange);
      await tester.pumpWidget(MaterialApp(theme: appThemeOf(brightness), home: Builder(builder: (built) {
        context = built;
        return Scaffold(
          body: Column(children: [
            Section(key: section, const [Text('x')]),
            SwipeToRemove(rowKey: row, mayRemove: false, onRemove: () async => '', side: statusSide, child: const Text('y')),
          ]),
        );
      })));

      OutlinedBorder shapeOf(Key cardKey) => tester.widget<Material>(find.descendant(of: find.byKey(cardKey), matching: find.byType(Material)).first).shape! as OutlinedBorder;
      expect(shapeOf(section.card).side.color, AppColor.frame.of(context));
      expect(shapeOf(row.card).side, statusSide);
    });
  }
}
