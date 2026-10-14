import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ispeak_admin_panel/screens/resources_screen.dart';
import 'package:ispeak_admin_panel/widgets/resource_icon.dart';
import 'admin_ui_test.dart' as fixtures;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(
    () =>
        SharedPreferences.setMockInitialValues({'auth_token': 'fixture-token'}),
  );

  test('icon registry supports search, categories and fallback', () {
    expect(
      ResourceIcon.filtered('All', 'mic').map((item) => item.name),
      containsAll(['mic', 'record_voice_over']),
    );
    expect(
      ResourceIcon.filtered('All', 'hear').map((item) => item.name),
      contains('hearing'),
    );
    expect(
      ResourceIcon.filtered('All', 'book').map((item) => item.name),
      contains('menu_book'),
    );
    expect(
      ResourceIcon.filtered('Audio', '').map((item) => item.name),
      containsAll(['volume_up', 'hearing', 'graphic_eq']),
    );
    expect(ResourceIcon.resolve('old_custom_icon'), ResourceIcon.fallback);
  });

  for (final dark in [false, true]) {
    testWidgets(
      'icon picker selects explicitly and cancel preserves dark=$dark',
      (tester) async {
        tester.view.physicalSize = const Size(600, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final data = fixtures.Fixture();
        data.resources.firstWhere(
          (row) => row['type'] == 'GuidedTask',
        )['iconName'] = 'old_custom_icon';
        await http.runWithClient(() async {
          await tester.pumpWidget(
            fixtures.app(const ResourcesScreen(), GlobalKey(), dark: dark),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const ValueKey('filter-GuidedTask')));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const ValueKey('edit-GuidedTask')));
          await tester.pumpAndSettle();
          final picker = find.byKey(const ValueKey('resource-icon-name'));
          await tester.ensureVisible(picker);
          expect(find.text('old_custom_icon'), findsOneWidget);
          expect(find.textContaining('Unsupported icon'), findsOneWidget);

          await tester.tap(picker);
          await tester.pumpAndSettle();
          expect(find.text('Choose Icon'), findsOneWidget);
          await tester.enterText(
            find.byKey(const ValueKey('icon-search')),
            'hear',
          );
          await tester.pump();
          expect(
            find.byKey(const ValueKey('icon-option-hearing')),
            findsOneWidget,
          );
          await tester.tap(find.byKey(const ValueKey('icon-option-hearing')));
          expect(find.text('hearing'), findsWidgets);
          await tester.tap(find.text('Cancel'));
          await tester.pumpAndSettle();
          expect(find.text('old_custom_icon'), findsOneWidget);

          await tester.tap(picker);
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const ValueKey('icon-category-Audio')));
          await tester.pump();
          expect(
            find.byKey(const ValueKey('icon-option-volume_up')),
            findsOneWidget,
          );
          expect(find.byKey(const ValueKey('icon-option-mic')), findsNothing);
          await tester.tap(find.byKey(const ValueKey('icon-option-hearing')));
          await tester.tap(find.byKey(const ValueKey('select-icon')));
          await tester.pumpAndSettle();
          expect(find.text('hearing'), findsOneWidget);
          await tester.ensureVisible(find.text('Update Resource'));
          await tester.tap(find.text('Update Resource'));
          await tester.pumpAndSettle();
          final request = data.requests.singleWhere(
            (item) => item.method == 'PUT',
          );
          expect(request.body, contains('hearing'));
          expect(tester.takeException(), isNull);
        }, data.client);
      },
    );
  }

  testWidgets('grouped drag order persists and search disables handles', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1024, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final data = fixtures.Fixture();
    data.resources.addAll([
      {
        '_id': 'Script-2',
        'type': 'Script',
        'title': 'Second advanced script',
        'description': 'Practice.',
        'difficulty': 'Advanced',
        'language': 'English',
        'displayOrder': 2,
      },
      {
        '_id': 'Script-beginner',
        'type': 'Script',
        'title': 'Beginner script',
        'description': 'Practice.',
        'difficulty': 'Beginner',
        'language': 'English',
        'displayOrder': 1,
      },
    ]);
    data.resources.firstWhere((row) => row['_id'] == 'Script')['displayOrder'] =
        1;
    await http.runWithClient(() async {
      await tester.pumpWidget(
        fixtures.app(const ResourcesScreen(), GlobalKey()),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('filter-Script')));
      await tester.pumpAndSettle();
      expect(find.text('Beginner — 1 resource'), findsOneWidget);
      expect(find.text('Advanced — 2 resources'), findsOneWidget);
      expect(find.byKey(const ValueKey('order-Script')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('drag-Script-beginner')),
        findsOneWidget,
      );

      final firstAdvanced = find.byKey(const ValueKey('drag-Script'));
      await tester.ensureVisible(firstAdvanced);
      final gesture = await tester.startGesture(
        tester.getCenter(firstAdvanced),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await gesture.moveBy(const Offset(0, 260));
      await tester.pump(const Duration(milliseconds: 500));
      await gesture.up();
      await tester.pumpAndSettle();
      final patch = data.requests.lastWhere(
        (request) => request.method == 'PATCH',
      );
      final payload = jsonDecode(patch.body) as Map<String, dynamic>;
      expect(payload['type'], 'Script');
      expect(payload['difficulty'], 'Advanced');
      expect(payload['orderedIds'], ['Script-2', 'Script']);

      await tester.pumpWidget(
        fixtures.app(const ResourcesScreen(), GlobalKey()),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('filter-Script')));
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(find.byKey(const ValueKey('resource-Script-2'))).dy,
        lessThan(
          tester.getTopLeft(find.byKey(const ValueKey('resource-Script'))).dy,
        ),
        reason: 'saved displayOrder must survive a fresh GET',
      );

      await tester.enterText(
        find.byKey(const ValueKey('resource-search')),
        'script',
      );
      await tester.pump();
      expect(find.text('Clear search to reorder resources.'), findsOneWidget);
      expect(find.byIcon(Icons.drag_indicator), findsNothing);
      expect(tester.takeException(), isNull);
    }, data.client);
  });

  testWidgets('failed Guided Task reorder restores confirmed order', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final data = fixtures.Fixture()
      ..failReorder = true
      ..resources.add({
        '_id': 'GuidedTask-2',
        'type': 'GuidedTask',
        'title': 'Second guided task',
        'description': 'Practice.',
        'difficulty': 'None',
        'language': 'English',
        'iconName': 'hearing',
        'displayOrder': 2,
      });
    data.resources.firstWhere(
      (row) => row['_id'] == 'GuidedTask',
    )['displayOrder'] = 1;
    await http.runWithClient(() async {
      await tester.pumpWidget(
        fixtures.app(const ResourcesScreen(), GlobalKey()),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('filter-GuidedTask')));
      await tester.pumpAndSettle();
      final handle = find.byKey(const ValueKey('drag-GuidedTask'));
      final destination = tester.getBottomLeft(
        find.byKey(const ValueKey('resource-GuidedTask-2')),
      );
      final handleOffset =
          tester.getCenter(handle).dy -
          tester
              .getTopLeft(find.byKey(const ValueKey('resource-GuidedTask')))
              .dy;
      final gesture = await tester.startGesture(tester.getCenter(handle));
      await tester.pump(const Duration(milliseconds: 100));
      // Move the proxy past the second card, accounting for unequal heights.
      await gesture.moveTo(
        Offset(tester.getCenter(handle).dx, destination.dy + handleOffset + 5),
      );
      await tester.pump(const Duration(milliseconds: 500));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(
        find.textContaining('previous order was restored'),
        findsOneWidget,
      );
      expect(
        tester.getTopLeft(find.byKey(const ValueKey('resource-GuidedTask'))).dy,
        lessThan(
          tester
              .getTopLeft(find.byKey(const ValueKey('resource-GuidedTask-2')))
              .dy,
        ),
      );
      expect(tester.takeException(), isNull);
    }, data.client);
  });
}
