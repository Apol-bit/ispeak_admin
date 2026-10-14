import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ispeak_admin_panel/screens/resources_screen.dart';
import 'package:ispeak_admin_panel/screens/main_layout.dart';
import 'package:ispeak_admin_panel/theme/app_theme.dart';
import 'package:ispeak_admin_panel/widgets/resource_icon.dart';
import 'package:ispeak_admin_panel/widgets/resource_icon_picker.dart';
import 'admin_ui_test.dart' as fixtures;

void main() {
  setUp(
    () =>
        SharedPreferences.setMockInitialValues({'auth_token': 'fixture-token'}),
  );

  for (final dark in [false, true]) {
    for (final width in [1366.0, 1024.0, 768.0, 600.0, 390.0, 320.0]) {
      testWidgets('category mouse scrolling at $width dark=$dark', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 650);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        String? selected;
        await tester.pumpWidget(
          fixtures.app(
            ResourceIconPickerField(
              value: 'mic',
              onChanged: (value) => selected = value,
            ),
            GlobalKey(),
            dark: dark,
          ),
        );
        await tester.tap(find.byKey(const ValueKey('resource-icon-name')));
        await tester.pumpAndSettle();
        for (final category in ResourceIcon.categories) {
          expect(
            find.byKey(ValueKey('icon-category-$category')),
            findsOneWidget,
          );
        }
        final row = find.byKey(const ValueKey('icon-category-scroll'));
        final controller = tester
            .widget<SingleChildScrollView>(row)
            .controller!;
        expect(controller.position.maxScrollExtent, greaterThan(0));
        final viewport = tester.getRect(row);
        // A real mouse drag, rather than ensureVisible/programmatic scrolling.
        while (controller.offset < controller.position.maxScrollExtent) {
          final before = controller.offset;
          await tester.dragFrom(
            viewport.centerRight - const Offset(15, 8),
            Offset(-viewport.width * .7, 0),
            kind: PointerDeviceKind.mouse,
          );
          await tester.pumpAndSettle();
          expect(controller.offset, greaterThan(before));
        }
        final general = find.byKey(const ValueKey('icon-category-General'));
        final communication = find.byKey(
          const ValueKey('icon-category-Communication'),
        );
        final chipRect = tester.getRect(general);
        expect(chipRect.left, greaterThanOrEqualTo(viewport.left));
        expect(chipRect.right, lessThanOrEqualTo(viewport.right));
        controller.jumpTo(0);
        await tester.pump();
        await tester.sendEventToBinding(
          PointerScrollEvent(
            position: viewport.center,
            scrollDelta: const Offset(1200, 0),
          ),
        );
        await tester.pumpAndSettle();
        expect(controller.offset, controller.position.maxScrollExtent);
        await tester.tap(general);
        await tester.pumpAndSettle();
        expect(tester.widget<ChoiceChip>(general).selected, isTrue);
        expect(
          tester.widget<ChoiceChip>(general).selectedColor,
          AppTheme.filterBlue,
        );
        expect(find.byKey(const ValueKey('icon-option-mic')), findsNothing);
        expect(find.byKey(const ValueKey('icon-option-bolt')), findsOneWidget);
        await tester.enterText(
          find.byKey(const ValueKey('icon-search')),
          'flash',
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('icon-option-flash_on')),
          findsOneWidget,
        );
        await tester.enterText(find.byKey(const ValueKey('icon-search')), '');
        await tester.ensureVisible(communication);
        await tester.tap(communication);
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('icon-option-forum')), findsOneWidget);
        await tester.ensureVisible(general);
        await tester.tap(general);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('icon-option-flash_on')));
        expect(find.text('Cancel').hitTestable(), findsOneWidget);
        expect(find.text('Select').hitTestable(), findsOneWidget);
        await tester.tap(find.text('Select'));
        await tester.pumpAndSettle();
        expect(selected, 'flash_on');
        expect(tester.takeException(), isNull);
      });
    }

    for (final width in [1024.0, 600.0]) {
      testWidgets('large resource list drag edges at $width dark=$dark', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final data = fixtures.Fixture();
        data.resources.addAll([
          for (var i = 0; i < 200; i++)
            {
              '_id': 'long-$i',
              'type': 'Challenge',
              'difficulty': 'Beginner',
              'title': 'Resource $i',
              'language': 'English',
              'displayOrder': i,
            },
        ]);
        await http.runWithClient(() async {
          await tester.pumpWidget(
            fixtures.app(const ResourcesScreen(), GlobalKey(), dark: dark),
          );
          await tester.pumpAndSettle();
          final mountedCards = find
              .byWidgetPredicate(
                (widget) =>
                    widget is Card &&
                    widget.key.toString().contains('resource-'),
              )
              .evaluate()
              .length;
          expect(
            mountedCards,
            lessThan(20),
            reason: '200 offscreen cards must stay lazy',
          );
          final scroll = find.byKey(const ValueKey('resource-scroll'));
          final controller = tester
              .widget<CustomScrollView>(scroll)
              .controller!;
          final viewport = tester.getRect(scroll);
          Future<void> frames(int count) async {
            for (var i = 0; i < count; i++) {
              await tester.pump(const Duration(milliseconds: 16));
            }
          }

          final handle = find.byKey(const ValueKey('drag-long-0'));
          final gesture = await tester.startGesture(
            tester.getCenter(handle),
            kind: PointerDeviceKind.mouse,
          );
          await tester.pump();
          await gesture.moveTo(
            Offset(tester.getCenter(handle).dx, viewport.bottom - 5),
          );
          await frames(90);
          expect(controller.offset, greaterThan(100));
          expect(data.requests.where((r) => r.method == 'PATCH'), isEmpty);
          await gesture.moveTo(viewport.center);
          await frames(10);
          final stopped = controller.offset;
          await frames(30);
          expect(controller.offset, stopped);
          await gesture.moveTo(Offset(viewport.center.dx, viewport.top + 2));
          await frames(30);
          expect(controller.offset, lessThan(stopped));
          await gesture.moveTo(Offset(viewport.center.dx, viewport.bottom - 5));
          await frames(90);
          final beforeDrop = controller.offset;
          await gesture.up();
          await tester.pump(const Duration(milliseconds: 16));
          expect(controller.offset, beforeDrop);
          await tester.pumpAndSettle();
          final patches = data.requests
              .where((r) => r.method == 'PATCH')
              .toList();
          expect(patches, hasLength(1));
          final payload =
              jsonDecode(patches.single.body) as Map<String, dynamic>;
          expect(payload['type'], 'Challenge');
          expect(payload['difficulty'], 'Beginner');
          final ids = (payload['orderedIds'] as List).cast<String>();
          expect(ids, hasLength(200));
          expect(ids.toSet(), hasLength(200));
          expect(ids.indexOf('long-0'), greaterThan(0));
          expect(ids.where((id) => !id.startsWith('long-')), isEmpty);
          final dropped = controller.offset;
          await frames(30);
          expect(controller.offset, dropped);
          controller.jumpTo(0);
          await tester.pumpAndSettle();
          final nextHandle = find.byKey(ValueKey('drag-${ids.first}'));
          final cancel = await tester.startGesture(
            tester.getCenter(nextHandle),
          );
          await tester.pump();
          await cancel.moveTo(Offset(viewport.center.dx, viewport.bottom - 5));
          await frames(30);
          final beforeCancel = controller.offset;
          await cancel.cancel();
          await tester.pump(const Duration(milliseconds: 16));
          expect(controller.offset, beforeCancel);
          await tester.pumpAndSettle();
          final cancelled = controller.offset;
          await frames(30);
          expect(controller.offset, cancelled);
          expect(data.requests.where((r) => r.method == 'PATCH'), hasLength(1));
          await tester.enterText(
            find.byKey(const ValueKey('resource-search')),
            'Resource',
          );
          await tester.pumpAndSettle();
          expect(find.byType(ReorderableDragStartListener), findsNothing);
          expect(data.requests.where((r) => r.method == 'GET'), hasLength(1));
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
          await tester.pumpAndSettle();
          expect(tester.binding.transientCallbackCount, 0);
        }, data.client);
      });
    }
  }

  testWidgets('drag stops at bounds and disposes while active', (tester) async {
    tester.view.physicalSize = const Size(1024, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final data = fixtures.Fixture();
    data.resources.clear();
    data.resources.addAll([
      for (var i = 0; i < 12; i++)
        {
          '_id': 'task-$i',
          'type': 'GuidedTask',
          'difficulty': 'None',
          'title': 'Task $i',
          'language': 'English',
          'displayOrder': i,
        },
    ]);
    await http.runWithClient(() async {
      await tester.pumpWidget(
        fixtures.app(const ResourcesScreen(), GlobalKey()),
      );
      await tester.pumpAndSettle();
      final scroll = find.byKey(const ValueKey('resource-scroll'));
      final controller = tester.widget<CustomScrollView>(scroll).controller!;
      final viewport = tester.getRect(scroll);
      Future<void> frames(int count) async {
        for (var i = 0; i < count; i++) {
          await tester.pump(const Duration(milliseconds: 16));
        }
      }

      controller.jumpTo(controller.position.maxScrollExtent);
      await tester.pumpAndSettle();
      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey('drag-task-11'))),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pump();
      await gesture.moveTo(viewport.bottomCenter - const Offset(0, 2));
      await frames(60);
      expect(controller.offset, controller.position.maxScrollExtent);
      await gesture.moveTo(viewport.topCenter + const Offset(0, 2));
      await frames(350);
      expect(controller.offset, controller.position.minScrollExtent);
      await frames(30);
      expect(controller.offset, 0);
      await gesture.cancel();
      await tester.pumpAndSettle();
      expect(data.requests.where((r) => r.method == 'PATCH'), isEmpty);
      final disposalDrag = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey('drag-task-0'))),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pump();
      await disposalDrag.moveTo(viewport.bottomCenter - const Offset(0, 2));
      await frames(30);
      expect(controller.offset, greaterThan(0));
      await tester.pumpWidget(const SizedBox());
      await disposalDrag.cancel();
      await tester.pumpAndSettle();
      expect(tester.binding.transientCallbackCount, 0);
      expect(tester.takeException(), isNull);
    }, data.client);
  });

  testWidgets('navigation issues one request per endpoint; theme issues none', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1366, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final data = fixtures.Fixture();
    await http.runWithClient(() async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MainLayout(adminName: 'Test', adminEmail: 'test@example.test'),
        ),
      );
      await tester.pumpAndSettle();
      for (final page in [1, 2, 3]) {
        await tester.tap(find.byKey(ValueKey('nav-$page')));
        await tester.pumpAndSettle();
      }
      for (final endpoint in [
        '/admin/stats',
        '/admin/recent-sessions',
        '/users',
        '/admin/ai-logs',
        '/resources',
      ]) {
        expect(
          data.requests.where((r) => r.url.path.endsWith(endpoint)),
          hasLength(1),
        );
      }
      final count = data.requests.length;
      await tester.tap(find.text('Switch to dark mode'));
      await tester.pumpAndSettle();
      expect(data.requests, hasLength(count));
      expect(tester.takeException(), isNull);
    }, data.client);
  });
}
