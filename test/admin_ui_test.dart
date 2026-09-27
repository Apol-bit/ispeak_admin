import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ispeak_admin_panel/screens/main_layout.dart';
import 'package:ispeak_admin_panel/screens/dashboard_screen.dart';
import 'package:ispeak_admin_panel/screens/users_screen.dart';
import 'package:ispeak_admin_panel/screens/session_reviews_screen.dart';
import 'package:ispeak_admin_panel/screens/resources_screen.dart';
import 'package:ispeak_admin_panel/theme/app_theme.dart';
import 'package:ispeak_admin_panel/widgets/admin_nav_item.dart';
import 'package:ispeak_admin_panel/widgets/resource_icon.dart';
import 'package:ispeak_admin_panel/widgets/loading_skeleton.dart';

class Fixture {
  Completer<void>? gate;
  bool fail = false;
  bool failReorder = false;
  bool empty = false;
  final requests = <http.Request>[];
  final resources = <Map<String, dynamic>>[
    for (final type in ['Challenge', 'GuidedTask', 'Script'])
      {
        '_id': type,
        'type': type,
        'title':
            '$type speech exercise with a long but readable resource title',
        'description': 'Practice speaking.',
        'difficulty': 'Advanced',
        'language': 'English',
        'iconName': type == 'GuidedTask' ? 'flash_on' : 'volume_up',
        'steps': ['Breathe.', 'Speak.'],
        'estimatedMinutes': 2,
        'timeLimitSeconds': 60,
      },
  ];
  final session = {
    '_id': '507f1f77bcf86cd799439022',
    'createdAt': '2026-09-26T08:00:00Z',
    'transcription': 'The correct saved session transcript.',
    'status': 'Completed',
    'overallScore': 80,
    'paceScore': 78,
    'clarityScore': 81,
    'energyScore': 82,
    'wpmScore': 130,
  };
  http.Client client() => MockClient((request) async {
    requests.add(request);
    if (gate != null) await gate!.future;
    if (fail) return http.Response('{}', 503);
    final route = request.url.path;
    if (failReorder &&
        request.method == 'PATCH' &&
        route.endsWith('/resources/reorder')) {
      return http.Response('{}', 503);
    }
    Object body = {};
    var status = 200;
    if (request.method != 'GET') {
      if (request.method == 'PATCH' && route.endsWith('/resources/reorder')) {
        final payload = jsonDecode(request.body) as Map<String, dynamic>;
        final ids = (payload['orderedIds'] as List).cast<String>();
        for (var index = 0; index < ids.length; index++) {
          resources.firstWhere(
            (resource) => resource['_id'] == ids[index],
          )['displayOrder'] = index + 1;
        }
        body = {
          'resources': ids
              .map((id) => resources.firstWhere((row) => row['_id'] == id))
              .toList(),
        };
      } else if (request.method == 'DELETE') {
        resources.removeWhere((r) => route.endsWith('/${r['_id']}'));
      }
      status = request.method == 'POST' ? 201 : 200;
    } else if (route.endsWith('/admin/stats')) {
      body = {
        'totalUsers': empty ? 0 : 2,
        'totalSessions': empty ? 0 : 1,
        'avgAppScore': empty ? 0 : 80,
      };
    } else if (route.endsWith('/users')) {
      body = {
        'activeUsers': empty
            ? []
            : [
                {
                  '_id': 'user1',
                  'firstName': 'Test',
                  'lastName': 'User',
                  'username': 'test',
                  'email': 'test@example.test',
                  'role': 'user',
                  'status': 'Active',
                  'createdAt': '2026-09-26T08:00:00Z',
                },
              ],
        'archivedUsers': [],
      };
    } else if (route.endsWith('/resources')) {
      body = empty ? [] : resources;
    } else if (route.endsWith('/admin/recent-sessions') ||
        route.endsWith('/admin/ai-logs')) {
      body = empty ? [] : [session];
    }
    return http.Response(
      jsonEncode(body),
      status,
      headers: {'content-type': 'application/json'},
    );
  });
}

Future<void> screenshot(WidgetTester tester, GlobalKey key, String name) async {
  if (!const bool.fromEnvironment('CAPTURE_UI')) return;
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final rendered = await boundary.toImage();
    final bytes = await rendered.toByteData(format: ui.ImageByteFormat.png);
    final file = File('build/admin-ui-previews/$name.png');
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(bytes!.buffer.asUint8List());
    rendered.dispose();
  });
}

Widget app(Widget child, GlobalKey key, {bool dark = false}) => RepaintBoundary(
  key: key,
  child: MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.materialTheme(dark),
    home: ThemeProvider(
      isDarkMode: dark,
      child: Scaffold(
        body: Padding(padding: const EdgeInsets.all(24), child: child),
      ),
    ),
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(
    () =>
        SharedPreferences.setMockInitialValues({'auth_token': 'fixture-token'}),
  );
  setUpAll(() async {
    // Widget tests have no platform fallback fonts. Supply the code font for
    // render previews; non-Windows runners use the bundled face as a fallback.
    final codeFont = File('C:/Windows/Fonts/consola.ttf');
    await (FontLoader('monospace')..addFont(
          codeFont.existsSync()
              ? codeFont.readAsBytes().then(
                  (bytes) => ByteData.sublistView(bytes),
                )
              : rootBundle.load('assets/fonts/Inter-Regular.ttf'),
        ))
        .load();
    await (FontLoader(
      'Inter',
    )..addFont(rootBundle.load('assets/fonts/Inter-Regular.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  test(
    'resource icons cover stored names, legacy supported names and fallback',
    () {
      expect(ResourceIcon.resolve('flash_on'), Icons.flash_on);
      expect(ResourceIcon.resolve('volume_up'), Icons.volume_up);
      expect(ResourceIcon.resolve('timer'), Icons.timer);
      for (final value in [null, '', 'unknown', 42]) {
        expect(ResourceIcon.resolve(value), ResourceIcon.fallback);
      }
    },
  );

  for (final dark in [false, true]) {
    testWidgets('narrow skeletons and resource editor dark=$dark', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      for (final width in [600.0, 768.0]) {
        tester.view.physicalSize = Size(width, 900);
        for (final screen in [
          const DashboardScreen(),
          const UsersScreen(),
          const SessionReviewsScreen(),
          const ResourcesScreen(),
        ]) {
          final data = Fixture()..gate = Completer<void>();
          final key = GlobalKey();
          await http.runWithClient(() async {
            await tester.pumpWidget(app(screen, key, dark: dark));
            await tester.pumpAndSettle();
            expect(find.byType(SkeletonList), findsOneWidget);
            for (final box in tester.widgetList<Container>(
              find.descendant(
                of: find.byType(SkeletonBox),
                matching: find.byType(Container),
              ),
            )) {
              expect(
                (box.decoration as BoxDecoration).color,
                dark ? const Color(0xFF253041) : const Color(0xFFEEF0F4),
              );
            }
            expect(tester.takeException(), isNull);
            await screenshot(
              tester,
              key,
              'narrow-skeleton-${screen.runtimeType}-$width-$dark',
            );
            data.gate!.complete();
            await tester.pumpAndSettle();
            if (screen is ResourcesScreen) {
              await tester.tap(find.text('Add Resource'));
              await tester.pumpAndSettle();
              await screenshot(tester, key, 'narrow-add-$width-$dark');
              await tester.tap(find.byIcon(Icons.close));
              await tester.pumpAndSettle();
            }
            expect(tester.takeException(), isNull);
          }, data.client);
        }
      }
    });
    testWidgets('resource filters, CRUD form and theme $dark', (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final data = Fixture();
      final key = GlobalKey();
      await http.runWithClient(() async {
        await tester.pumpWidget(app(const ResourcesScreen(), key, dark: dark));
        await tester.pumpAndSettle();
        await screenshot(tester, key, 'resources-$dark');
        for (final type in ['All', 'Challenge', 'GuidedTask', 'Script']) {
          await tester.tap(find.byKey(ValueKey('filter-$type')));
          await tester.pumpAndSettle();
          final chips = tester
              .widgetList<ChoiceChip>(find.byType(ChoiceChip))
              .toList();
          expect(chips.where((chip) => chip.selected).length, 1);
          for (final chip in chips) {
            expect(chip.selectedColor, AppTheme.filterBlue);
            expect(chip.surfaceTintColor, Colors.transparent);
            expect(
              chip.side!.color,
              chip.selected
                  ? AppTheme.filterBlue
                  : dark
                  ? AppTheme.darkBorder
                  : AppTheme.lightFilterBorder,
            );
            expect(
              chip.backgroundColor,
              dark ? AppTheme.darkSurface : Colors.white,
            );
            expect(
              chip.labelStyle!.color,
              chip.selected
                  ? Colors.white
                  : dark
                  ? const Color(0xFFCBD5E1)
                  : AppTheme.lightFilterText,
            );
          }
          if (type != 'All') {
            expect(find.byKey(ValueKey('resource-$type')), findsOneWidget);
            expect(find.byKey(ValueKey('count-$type')), findsOneWidget);
          }
          await screenshot(tester, key, 'filter-$type-$dark');
        }
        await tester.enterText(
          find.byKey(const ValueKey('resource-search')),
          'SPEECH',
        );
        await tester.pump();
        expect(find.byKey(const ValueKey('resource-Script')), findsOneWidget);
        expect(find.byKey(const ValueKey('resource-Challenge')), findsNothing);
        await tester.enterText(
          find.byKey(const ValueKey('resource-search')),
          'missing',
        );
        await tester.pump();
        expect(find.textContaining('No resources found'), findsOneWidget);
        await tester.enterText(
          find.byKey(const ValueKey('resource-search')),
          '',
        );
        await tester.tap(find.byKey(const ValueKey('filter-GuidedTask')));
        await tester.pumpAndSettle();
        expect(find.text('All Levels'), findsOneWidget);
        expect(find.text('Advanced'), findsNothing);
        expect(find.byIcon(Icons.flash_on), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('edit-GuidedTask')));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('resource-difficulty')), findsNothing);
        expect(
          find.text('Open to all levels — no difficulty gate'),
          findsOneWidget,
        );
        await screenshot(tester, key, 'edit-guided-$dark');
        for (final type in ['Script', 'Challenge', 'GuidedTask']) {
          await tester.ensureVisible(
            find.byKey(const ValueKey('resource-type')),
          );
          await tester.tap(find.byKey(const ValueKey('resource-type')));
          await tester.pumpAndSettle();
          await tester.tap(
            find.text(type == 'GuidedTask' ? 'Guided Task' : type).last,
          );
          await tester.pumpAndSettle();
          expect(
            find.byKey(const ValueKey('resource-difficulty')),
            type == 'GuidedTask' ? findsNothing : findsOneWidget,
          );
        }
        final icon = find.byKey(const ValueKey('resource-icon-name'));
        await tester.ensureVisible(icon);
        await tester.pumpAndSettle();
        await tester.tap(icon);
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const ValueKey('icon-search')),
          'volume',
        );
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey('icon-option-volume_up')));
        await tester.tap(find.byKey(const ValueKey('select-icon')));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Update Resource'));
        await tester.tap(find.text('Update Resource'));
        await tester.pumpAndSettle();
        final update = data.requests.singleWhere((r) => r.method == 'PUT');
        expect(update.url.path, endsWith('/admin/resources/GuidedTask'));
        expect(update.body, contains('name="iconName"'));
        expect(update.body, contains('volume_up'));
        expect(
          update.body,
          contains('Advanced'),
          reason: 'legacy difficulty metadata must survive editing',
        );
        await tester.tap(find.byKey(const ValueKey('delete-GuidedTask')));
        await tester.pumpAndSettle();
        final dialog = tester.widget<AlertDialog>(find.byType(AlertDialog));
        expect(
          Theme.of(tester.element(find.byType(AlertDialog))).brightness,
          dark ? Brightness.dark : Brightness.light,
        );
        expect(dialog.title, isNotNull);
        await screenshot(tester, key, 'delete-$dark');
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(data.requests.where((r) => r.method == 'DELETE'), isEmpty);
        await tester.tap(find.byKey(const ValueKey('delete-GuidedTask')));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(ElevatedButton, 'Delete'));
        await tester.pumpAndSettle();
        expect(data.requests.where((r) => r.method == 'DELETE').length, 1);
        await tester.tap(find.text('Add Resource'));
        await tester.pumpAndSettle();
        await screenshot(tester, key, 'add-$dark');
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Title (e.g., Quick Pitch)'),
          'New guided exercise',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Short Description'),
          'Practice',
        );
        await tester.tap(find.byKey(const ValueKey('resource-type')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Guided Task').last);
        await tester.pumpAndSettle();
        await tester.ensureVisible(icon);
        await tester.pumpAndSettle();
        await tester.tap(icon);
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const ValueKey('icon-search')),
          'flash',
        );
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey('icon-option-flash_on')));
        await tester.ensureVisible(find.byKey(const ValueKey('select-icon')));
        await tester.tap(find.byKey(const ValueKey('select-icon')));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Save Resource'));
        await tester.tap(find.text('Save Resource'));
        await tester.pumpAndSettle();
        final create = data.requests.singleWhere((r) => r.method == 'POST');
        expect(create.body, contains('name="iconName"'));
        expect(create.body, contains('flash_on'));
        expect(tester.takeException(), isNull);
      }, data.client);
    });

    for (final width in [768.0, 1024.0, 1440.0]) {
      testWidgets(
        'navigation, dashboard cards and shared detail $width dark=$dark',
        (tester) async {
          tester.view.physicalSize = Size(width, width == 768 ? 1024 : 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          final data = Fixture();
          final key = GlobalKey();
          await http.runWithClient(() async {
            await tester.pumpWidget(
              RepaintBoundary(
                key: key,
                child: const MaterialApp(
                  debugShowCheckedModeBanner: false,
                  home: MainLayout(
                    adminName: 'Admin',
                    adminEmail: 'admin@example.test',
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            if (dark) {
              await tester.tap(
                width < 800
                    ? find.byIcon(Icons.dark_mode)
                    : find.text('Switch to dark mode'),
              );
              await tester.pumpAndSettle();
            }
            Future<void> navigate(int index) async {
              if (width < 800) {
                tester
                    .state<ScaffoldState>(find.byType(Scaffold).first)
                    .openDrawer();
                await tester.pumpAndSettle();
              }
              final item = find.byKey(ValueKey('nav-$index'));
              expect(
                tester.widget<AdminNavItem>(item).label,
                ['Dashboard', 'Users', 'Session Reviews', 'Resources'][index],
              );
              await tester.tap(item);
              await tester.pumpAndSettle();
            }

            await screenshot(tester, key, 'dashboard-$width-$dark');
            for (final entry in [
              ('Total Users', 1),
              ('Total Sessions', 2),
              ('Avg App Score', 2),
            ]) {
              final card = find.byKey(ValueKey('stat-${entry.$1}'));
              await tester.tapAt(
                tester.getBottomRight(card) - const Offset(8, 8),
              );
              await tester.pumpAndSettle();
              expect(
                find.byType(entry.$2 == 1 ? UsersScreen : SessionReviewsScreen),
                findsOneWidget,
              );
              await navigate(0);
            }
            final table = tester.widget<DataTable>(find.byType(DataTable));
            expect(table.showCheckboxColumn, isFalse);
            expect(table.rows.single.onSelectChanged, isNotNull);
            expect(
              table.rows.single.color!.resolve({WidgetState.hovered}),
              isNot(table.rows.single.color!.resolve({})),
            );
            // Tap the padded row area, not an action icon.
            await tester.tapAt(
              tester.getCenter(find.text('507f1f77...')) + const Offset(0, 20),
            );
            await tester.pumpAndSettle();
            expect(find.text('Session Analysis Details'), findsOneWidget);
            expect(find.text(data.session['_id'] as String), findsOneWidget);
            await screenshot(tester, key, 'session-detail-$width-$dark');
            await tester.tap(find.byIcon(Icons.close));
            await tester.pumpAndSettle();
            for (var index = 1; index < 4; index++) {
              await navigate(index);
              expect(tester.takeException(), isNull);
              await screenshot(tester, key, 'page-$index-$width-$dark');
              if (width >= 800) {
                expect(
                  tester
                      .widget<AdminNavItem>(find.byKey(ValueKey('nav-$index')))
                      .selected,
                  isTrue,
                );
              }
            }
            if (width < 800) {
              tester
                  .state<ScaffoldState>(find.byType(Scaffold).first)
                  .openDrawer();
              await tester.pumpAndSettle();
              expect(
                tester
                    .widget<AdminNavItem>(find.byKey(const ValueKey('nav-3')))
                    .selected,
                isTrue,
              );
              await screenshot(tester, key, 'drawer-$dark');
            }
          }, data.client);
        },
      );
    }

    for (final screen in [
      const DashboardScreen(),
      const UsersScreen(),
      const SessionReviewsScreen(),
      const ResourcesScreen(),
    ]) {
      for (final outcome in ['success', 'empty', 'error']) {
        testWidgets('${screen.runtimeType} skeleton to $outcome dark=$dark', (
          tester,
        ) async {
          tester.view.physicalSize = const Size(1024, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          final data = Fixture()
            ..gate = Completer<void>()
            ..empty = outcome == 'empty'
            ..fail = outcome == 'error';
          final key = GlobalKey();
          await http.runWithClient(() async {
            await tester.pumpWidget(app(screen, key, dark: dark));
            await tester.pumpAndSettle();
            expect(find.byType(SkeletonList), findsWidgets);
            expect(find.textContaining('No resources'), findsNothing);
            expect(find.byType(CircularProgressIndicator), findsNothing);
            if (outcome == 'success') {
              await screenshot(
                tester,
                key,
                'skeleton-${screen.runtimeType}-$dark',
              );
            }
            final initialRequests = data.requests.length;
            await tester.pump(const Duration(seconds: 2));
            expect(data.requests.length, initialRequests);
            data.gate!.complete();
            await tester.pumpAndSettle();
            expect(find.byType(SkeletonList), findsNothing);
            expect(find.byType(SkeletonSummaryCards), findsNothing);
            if (outcome == 'error') {
              expect(find.text('Try Again'), findsWidgets);
            }
            if (outcome == 'empty') {
              expect(find.textContaining('No '), findsWidgets);
            }
            expect(tester.takeException(), isNull);
          }, data.client);
        });
      }
    }
  }
}
