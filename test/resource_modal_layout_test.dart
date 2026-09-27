import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ispeak_admin_panel/screens/resources_screen.dart';
import 'package:ispeak_admin_panel/screens/main_layout.dart';
import 'admin_ui_test.dart' as fixtures;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(
    () =>
        SharedPreferences.setMockInitialValues({'auth_token': 'fixture-token'}),
  );
  setUpAll(() async {
    await (FontLoader(
      'Inter',
    )..addFont(rootBundle.load('assets/fonts/Inter-Regular.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  for (final dark in [false, true]) {
    testWidgets('sidebar expansion frames on Resources dark=$dark', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final data = fixtures.Fixture();
      await http.runWithClient(() async {
        await tester.pumpWidget(
          const MaterialApp(
            home: MainLayout(
              adminName: 'Test',
              adminEmail: 'test@example.test',
            ),
          ),
        );
        await tester.pumpAndSettle();
        if (dark) {
          await tester.tap(find.text('Switch to dark mode'));
          await tester.pumpAndSettle();
        }
        await tester.tap(find.byKey(const ValueKey('nav-3')));
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.menu));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(Image).first);
        await tester.pump();
        expect(
          tester.takeException(),
          isNull,
          reason: 'first expansion frame: sidebar remains 72 px',
        );
        for (var frame = 0; frame < 15; frame++) {
          await tester.pump(const Duration(milliseconds: 16));
          expect(
            tester.takeException(),
            isNull,
            reason: 'sidebar expansion frame $frame',
          );
        }
        await tester.pumpAndSettle();
        await tester.tap(find.text('Add Resource'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }, data.client);
    });
    for (final width in [1366.0, 1024.0, 768.0, 600.0, 390.0, 320.0]) {
      testWidgets('resource modal controls at $width dark=$dark', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 650);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final data = fixtures.Fixture();
        final key = GlobalKey();
        await http.runWithClient(() async {
          await tester.pumpWidget(
            fixtures.app(const ResourcesScreen(), key, dark: dark),
          );
          await tester.pumpAndSettle();
          for (final editing in [false, true]) {
            final saveLabel = editing ? 'Update Resource' : 'Save Resource';
            if (editing) {
              await tester.tap(find.byKey(const ValueKey('filter-GuidedTask')));
              await tester.pumpAndSettle();
              await tester.ensureVisible(
                find.byKey(const ValueKey('edit-GuidedTask')),
              );
              await tester.pumpAndSettle();
              await tester.tap(find.byKey(const ValueKey('edit-GuidedTask')));
            } else {
              await tester.tap(find.text('Add Resource'));
            }
            await tester.pumpAndSettle();
            expect(
              tester.takeException(),
              isNull,
              reason: 'opening Add Resource',
            );
            Future<void> choose(String key, String value) async {
              final field = find.byKey(ValueKey(key));
              await tester.ensureVisible(field);
              await tester.tap(field);
              await tester.pumpAndSettle();
              await tester.tap(find.text(value).last);
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull, reason: '$key => $value');
            }

            final title = find.widgetWithText(
              TextFormField,
              'Title (e.g., Quick Pitch)',
            );
            await tester.ensureVisible(title);
            await tester.enterText(title, 'Responsive resource fixture');
            final description = find.widgetWithText(
              TextFormField,
              'Short Description',
            );
            await tester.ensureVisible(description);
            await tester.enterText(description, 'Exercise all modal controls.');

            for (final type in ['GuidedTask', 'Script', 'Challenge']) {
              await choose(
                'resource-type',
                type == 'GuidedTask' ? 'Guided Task' : type,
              );
              if (type == 'GuidedTask') {
                expect(
                  find.byKey(const ValueKey('resource-difficulty')),
                  findsNothing,
                );
                expect(
                  find.text('Open to all levels — no difficulty gate'),
                  findsOneWidget,
                );
                await choose('resource-language-$type', 'None');
                final icon = find.byKey(const ValueKey('resource-icon-name'));
                await tester.ensureVisible(icon);
                await tester.tap(icon);
                await tester.pumpAndSettle();
                expect(find.byKey(const ValueKey('icon-grid')), findsOneWidget);
                await tester.enterText(
                  find.byKey(const ValueKey('icon-search')),
                  'flash',
                );
                await tester.pump();
                expect(
                  find.byKey(const ValueKey('icon-option-flash_on')),
                  findsOneWidget,
                );
                await fixtures.screenshot(
                  tester,
                  key,
                  'modal-icon-$width-$dark-$editing',
                );
                await tester.tap(
                  find.byKey(const ValueKey('icon-option-flash_on')),
                );
                await tester.tap(find.byKey(const ValueKey('select-icon')));
                await tester.pumpAndSettle();
                expect(find.byIcon(Icons.flash_on), findsWidgets);
                if (width == 600 && !dark && !editing) {
                  final category = find.widgetWithText(
                    TextFormField,
                    'Category',
                  );
                  await tester.ensureVisible(category);
                  await tester.enterText(category, 'Keep my unsaved category');
                  for (final resizedWidth in [1024.0, 600.0]) {
                    tester.view.physicalSize = Size(resizedWidth, 650);
                    await tester.pumpAndSettle();
                    expect(
                      find.text('Keep my unsaved category'),
                      findsOneWidget,
                    );
                    expect(tester.takeException(), isNull);
                  }
                }
              } else {
                await choose('resource-difficulty', 'Intermediate');
                if (type == 'Challenge') {
                  final prompt = find.widgetWithText(
                    TextFormField,
                    'Prompt / Context',
                  );
                  expect(
                    tester
                        .widget<EditableText>(
                          find.descendant(
                            of: prompt,
                            matching: find.byType(EditableText),
                          ),
                        )
                        .controller
                        .text,
                    isEmpty,
                    reason:
                        'switching types must not reuse Estimated Time as Prompt',
                  );
                }
              }
              await choose('resource-language-$type', 'Filipino');
              await tester.ensureVisible(find.text(saveLabel));
              await tester.pumpAndSettle();
              expect(find.text(saveLabel).hitTestable(), findsOneWidget);
              await fixtures.screenshot(
                tester,
                key,
                'modal-actions-$type-$width-$dark-$editing',
              );
              expect(
                tester.takeException(),
                isNull,
                reason: 'complete $type form',
              );
            }
            await tester.tap(find.text(saveLabel));
            await tester.pumpAndSettle();
            expect(find.byType(Dialog), findsNothing);
            final saved = data.requests.singleWhere(
              (request) => request.method == (editing ? 'PUT' : 'POST'),
            );
            expect(saved.body, contains('Responsive resource fixture'));
            expect(saved.body, contains('Intermediate'));
            expect(saved.body, contains('Filipino'));
            expect(tester.takeException(), isNull);
          }
        }, data.client);
      });
    }
  }
}
