import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snap_floater/snap_floater.dart';

Widget _app(Widget button, {ThemeData? theme}) => MaterialApp(
  theme: theme,
  home: Scaffold(body: Center(child: button)),
);

Color? _iconColor(WidgetTester tester) =>
    tester.widget<Icon>(find.byIcon(Icons.code)).color;

void main() {
  group('BasicSnapFloaterButton', () {
    testWidgets('tap invokes onTap', (tester) async {
      var taps = 0;
      await tester.pumpWidget(_app(BasicSnapFloaterButton(() => taps++)));
      await tester.tap(find.byType(IconButton));
      expect(taps, 1);
    });

    testWidgets('null onTap renders a disabled button', (tester) async {
      await tester.pumpWidget(_app(const BasicSnapFloaterButton(null)));
      expect(
        tester.widget<IconButton>(find.byType(IconButton)).onPressed,
        isNull,
      );
    });

    testWidgets('has a border and is circular', (tester) async {
      await tester.pumpWidget(_app(BasicSnapFloaterButton(() {})));
      final box = tester.widget<DecoratedBox>(
        find
            .descendant(
              of: find.byType(BasicSnapFloaterButton),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      final deco = box.decoration as BoxDecoration;
      expect(deco.shape, BoxShape.circle);
      expect(deco.border, isNotNull);
    });

    testWidgets('border is lighter in dark theme, darker in light theme', (
      tester,
    ) async {
      Future<double> borderLightness(Brightness b) async {
        await tester.pumpWidget(
          _app(
            BasicSnapFloaterButton(() {}),
            theme: ThemeData(
              brightness: b,
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.teal,
                brightness: b,
              ),
            ),
          ),
        );
        // MaterialApp animates theme changes (AnimatedTheme, 200ms).
        await tester.pumpAndSettle();
        final deco =
            tester
                    .widget<DecoratedBox>(
                      find
                          .descendant(
                            of: find.byType(BasicSnapFloaterButton),
                            matching: find.byType(DecoratedBox),
                          )
                          .first,
                    )
                    .decoration
                as BoxDecoration;
        final primary = Theme.of(
          tester.element(find.byType(IconButton)),
        ).colorScheme.primary;
        final border = (deco.border! as Border).top.color;
        return HSLColor.fromColor(border).lightness -
            HSLColor.fromColor(primary).lightness;
      }

      expect(await borderLightness(Brightness.light), lessThan(0));
      expect(await borderLightness(Brightness.dark), greaterThan(0));
    });

    testWidgets(
      '[#16] icon color equals colorScheme.onPrimary (default theme)',
      (tester) async {
        await tester.pumpWidget(_app(BasicSnapFloaterButton(() {})));
        final scheme = Theme.of(
          tester.element(find.byIcon(Icons.code)),
        ).colorScheme;
        expect(_iconColor(tester), scheme.onPrimary);
      },
    );

    testWidgets(
      '[#16] icon color is still onPrimary when buttonTheme has no colorScheme',
      (tester) async {
        final theme = ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          buttonTheme: const ButtonThemeData(), // colorScheme == null
        );
        await tester.pumpWidget(
          _app(BasicSnapFloaterButton(() {}), theme: theme),
        );

        expect(
          _iconColor(tester),
          theme.colorScheme.onPrimary,
          reason:
              'Theme.buttonTheme.colorScheme is nullable and legacy; '
              'ThemeData.colorScheme is the source of truth',
        );
      },
    );
  });
}
