import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trackly/core/database/app_database.dart';
import 'package:trackly/features/subscriptions/application/catalog_backfill.dart';
import 'package:trackly/features/subscriptions/application/subscription_creator.dart';
import 'package:trackly/features/subscriptions/application/subscription_edit.dart';
import 'package:trackly/features/subscriptions/domain/recurring_enums.dart';
import 'package:trackly/features/subscriptions/domain/recurring_item.dart';
import 'package:trackly/features/home/widgets/subscription_row.dart';
import 'package:trackly/features/subscriptions/domain/service_catalog.dart';
import 'package:trackly/shared/widgets/service_icon.dart';

import '../../helpers/test_app.dart';

final _now = DateTime(2026, 10, 9, 12);

NewSubscription _new(String name, {String? logoKey, String? categoryId}) {
  return NewSubscription(
    name: name,
    amount: 10,
    currencyCode: 'USD',
    frequency: BillingFrequency.monthly,
    startDate: DateTime(2026, 10, 9),
    entryMethod: EntryMethod.quickAdd,
    logoKey: logoKey,
    categoryId: categoryId,
  );
}

RecurringItem _item(
  String id,
  String name, {
  String? logoKey,
  String? categoryId,
}) {
  return RecurringItem(
    id: id,
    name: name,
    type: RecurringItemType.subscription,
    amount: 10,
    currencyCode: 'USD',
    frequency: BillingFrequency.monthly,
    startDate: DateTime(2026, 1, 15),
    nextDueDate: DateTime(2026, 10, 15),
    logoKey: logoKey,
    categoryId: categoryId,
    createdAt: _now,
    updatedAt: _now,
  );
}

void main() {
  final withLogo = serviceCatalog.where((s) => s.logoAsset != null).toList();

  group('every logo really renders', () {
    for (final service in withLogo) {
      testWidgets(service.key, (tester) async {
        final boundary = GlobalKey();
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: RepaintBoundary(
                key: boundary,
                child: Container(
                  width: 96,
                  height: 96,
                  color: Colors.white,
                  padding: const EdgeInsets.all(12),
                  child: SvgPicture.asset(service.logoAsset!),
                ),
              ),
            ),
          ),
        );
        // The SVG is parsed asynchronously.
        for (var i = 0; i < 8; i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 20)),
          );
          await tester.pump();
        }
        expect(tester.takeException(), isNull);

        // Something was drawn: not a blank white square.
        final bytes = await tester.runAsync(() async {
          final render =
              boundary.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          final image = await render.toImage();
          final data = await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          );
          return data!.buffer.asUint8List();
        });
        expect(
          _drawnPixels(bytes!),
          greaterThan(150),
          reason: '${service.key} drew almost nothing',
        );
      });
    }
  });

  group('ServiceIcon', () {
    tracklyTest('shows the logo for a catalog service that has one', (
      tester,
    ) async {
      await pumpTrackly(
        tester,
        items: [testItem('Netflix', logoKey: 'netflix')],
      );
      expect(
        find.descendant(
          of: find.byType(ServiceIcon),
          matching: find.byType(SvgPicture),
        ),
        findsOneWidget,
      );
    });

    tracklyTest('a logo fills the whole icon: no tile, border or padding', (
      tester,
    ) async {
      await pumpTrackly(
        tester,
        items: [testItem('Netflix', logoKey: 'netflix')],
      );

      final icon = find.byType(ServiceIcon);
      final logo = find.descendant(of: icon, matching: find.byType(SvgPicture));
      // Nothing frames it: no container, decoration or padding.
      for (final wrapper in [
        find.byType(Container),
        find.byType(DecoratedBox),
        find.byType(Padding),
      ]) {
        expect(find.descendant(of: icon, matching: wrapper), findsNothing);
      }
      // And it is exactly as big as the icon element.
      expect(tester.getSize(logo), tester.getSize(icon));
      expect(tester.getSize(logo), const Size(44, 44));
    });

    tracklyTest('a logo is rounded like the other icons', (tester) async {
      await pumpTrackly(
        tester,
        items: [testItem('Netflix', logoKey: 'netflix')],
      );

      final clip = tester.widget<ClipRRect>(
        find.descendant(
          of: find.byType(ServiceIcon),
          matching: find.byType(ClipRRect),
        ),
      );
      // 30% of the icon size: 13.2 dp on a 44 dp icon.
      expect(clip.borderRadius, BorderRadius.circular(44 * 0.3));
    });

    tracklyTest('logo, mark and category icons all share one corner radius', (
      tester,
    ) async {
      await pumpTrackly(
        tester,
        size: const Size(390, 1800),
        items: [
          testItem('Netflix', due: DateTime(2026, 10, 12), logoKey: 'netflix'),
          testItem('Hulu', due: DateTime(2026, 10, 13), logoKey: 'hulu'),
          testItem('Gym', due: DateTime(2026, 10, 14)),
        ],
      );

      Finder iconOf(String name) => find.ancestor(
        of: find.text(name),
        matching: find.byType(SubscriptionRow),
      );
      BorderRadius tileRadius(String name) {
        final tile = tester.widget<Container>(
          find.descendant(
            of: find.descendant(
              of: iconOf(name),
              matching: find.byType(ServiceIcon),
            ),
            matching: find.byType(Container),
          ),
        );
        return (tile.decoration as BoxDecoration).borderRadius! as BorderRadius;
      }

      final logoRadius = tester
          .widget<ClipRRect>(
            find.descendant(
              of: find.descendant(
                of: iconOf('Netflix'),
                matching: find.byType(ServiceIcon),
              ),
              matching: find.byType(ClipRRect),
            ),
          )
          .borderRadius;

      expect(tileRadius('Hulu'), logoRadius); // Trackly mark tile
      expect(tileRadius('Gym'), logoRadius); // category icon
    });

    tracklyTest('the logo fills the larger detail-screen icon too', (
      tester,
    ) async {
      await pumpTrackly(
        tester,
        size: const Size(390, 1400),
        items: [
          testItem('Netflix', due: DateTime(2026, 10, 15), logoKey: 'netflix'),
        ],
      );
      await tester.tap(find.text('Netflix'));
      await settle(tester);

      final icon = find.byType(ServiceIcon);
      expect(tester.getSize(icon), const Size(56, 56));
      expect(
        tester.getSize(
          find.descendant(of: icon, matching: find.byType(SvgPicture)),
        ),
        const Size(56, 56),
      );
    });

    tracklyTest('black marks turn white on the dark theme', (tester) async {
      await pumpTrackly(
        tester,
        themeMode: ThemeMode.dark,
        items: [testItem('Apple TV+', logoKey: 'apple_tv_plus')],
      );
      final logo = tester.widget<SvgPicture>(
        find.descendant(
          of: find.byType(ServiceIcon),
          matching: find.byType(SvgPicture),
        ),
      );
      expect(
        logo.colorFilter,
        const ColorFilter.mode(Colors.white, BlendMode.srcIn),
      );
    });

    tracklyTest('black marks keep their own color on the light theme', (
      tester,
    ) async {
      await pumpTrackly(
        tester,
        items: [testItem('Apple TV+', logoKey: 'apple_tv_plus')],
      );
      final logo = tester.widget<SvgPicture>(
        find.descendant(
          of: find.byType(ServiceIcon),
          matching: find.byType(SvgPicture),
        ),
      );
      expect(logo.colorFilter, isNull);
    });

    tracklyTest('colored logos are never recolored, in either theme', (
      tester,
    ) async {
      for (final mode in [ThemeMode.light, ThemeMode.dark]) {
        await pumpTrackly(
          tester,
          themeMode: mode,
          items: [testItem('Netflix', logoKey: 'netflix')],
        );
        final logo = tester.widget<SvgPicture>(
          find.descendant(
            of: find.byType(ServiceIcon),
            matching: find.byType(SvgPicture),
          ),
        );
        expect(logo.colorFilter, isNull, reason: mode.name);
        // Unmount so the next pump starts clean (tracklyTest cleans up once).
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      }
    });

    tracklyTest('a catalog service without a logo shows the Trackly mark', (
      tester,
    ) async {
      await pumpTrackly(tester, items: [testItem('Hulu', logoKey: 'hulu')]);
      final svg = tester.widget<SvgPicture>(
        find.descendant(
          of: find.byType(ServiceIcon),
          matching: find.byType(SvgPicture),
        ),
      );
      expect(
        (svg.bytesLoader as SvgAssetLoader).assetName,
        'assets/illustrations/trackly_logo.svg',
      );
      // Drawn in one muted color, not the full-color artwork.
      expect(svg.colorFilter, isNotNull);
      expect(
        find.descendant(of: find.byType(ServiceIcon), matching: find.text('H')),
        findsNothing,
      );
    });

    tracklyTest('a generic entry like Gym membership shows its category icon', (
      tester,
    ) async {
      await pumpTrackly(
        tester,
        items: [testItem('Gym membership', logoKey: 'gym_membership')],
      );
      expect(
        find.descendant(
          of: find.byType(ServiceIcon),
          matching: find.byType(SvgPicture),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byType(ServiceIcon),
          matching: find.byType(Icon),
        ),
        findsOneWidget,
      );
    });

    tracklyTest('a generic bill shows its category icon, not the mark', (
      tester,
    ) async {
      await pumpTrackly(tester, items: [testItem('Rent', logoKey: 'rent')]);
      expect(
        find.descendant(
          of: find.byType(ServiceIcon),
          matching: find.byType(SvgPicture),
        ),
        findsNothing,
      );
      final icon = tester.widget<Icon>(
        find.descendant(
          of: find.byType(ServiceIcon),
          matching: find.byType(Icon),
        ),
      );
      expect(icon.icon, categoryIconData('housing'));
    });

    tracklyTest('a custom item keeps its category icon', (tester) async {
      await pumpTrackly(tester, items: [testItem('Pottery class')]);
      expect(
        find.descendant(
          of: find.byType(ServiceIcon),
          matching: find.byType(SvgPicture),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byType(ServiceIcon),
          matching: find.byType(Icon),
        ),
        findsOneWidget,
      );
    });
  });

  group('typed names pick up the catalog service', () {
    test('a typed catalog name gets its logo key and category', () {
      final item = buildRecurringItem(_new('netflix'), id: 'a', now: _now);
      expect(item.logoKey, 'netflix');
      expect(item.categoryId, 'entertainment');
      expect(item.name, 'netflix'); // the user's spelling is kept
    });

    test('an explicit choice wins over the name', () {
      final item = buildRecurringItem(
        _new('Netflix', logoKey: 'spotify', categoryId: 'fitness'),
        id: 'a',
        now: _now,
      );
      expect(item.logoKey, 'spotify');
      expect(item.categoryId, 'fitness');
    });

    test('a custom name gets nothing', () {
      final item = buildRecurringItem(
        _new('Netflix family'),
        id: 'a',
        now: _now,
      );
      expect(item.logoKey, isNull);
      expect(item.categoryId, isNull);
    });

    test('a typed name keeps a category the user picked', () {
      final item = buildRecurringItem(
        _new('Spotify', categoryId: 'health'),
        id: 'a',
        now: _now,
      );
      expect(item.logoKey, 'spotify');
      expect(item.categoryId, 'health');
    });

    test('renaming an item to a catalog name gives it the logo', () {
      final original = _item('a', 'My streaming');
      final edited = buildEditedItem(
        original,
        EditedSubscription(
          name: 'Max',
          type: RecurringItemType.subscription,
          amount: 10,
          currencyCode: 'USD',
          frequency: BillingFrequency.monthly,
          nextDueDate: DateTime(2026, 10, 15),
          remindersEnabled: true,
          reminderDaysBefore: 3,
        ),
        now: _now,
      );
      expect(edited.logoKey, 'max');
    });
  });

  group('backfillCatalogLogos', () {
    late AppDatabase db;

    setUp(() => db = AppDatabase(NativeDatabase.memory()));
    tearDown(() => db.close());

    Future<RecurringItem> stored(String id) async =>
        (await db.recurringItemsDao.getById(id))!;

    test('gives matching items their key and category', () async {
      await db.recurringItemsDao.insertItem(_item('a', 'Netflix'));
      await db.recurringItemsDao.insertItem(_item('b', '  SPOTIFY '));

      expect(await backfillCatalogLogos(db), 2);

      expect((await stored('a')).logoKey, 'netflix');
      expect((await stored('a')).categoryId, 'entertainment');
      expect((await stored('b')).logoKey, 'spotify');
    });

    test('leaves custom items alone', () async {
      await db.recurringItemsDao.insertItem(_item('a', 'Gym near home'));
      expect(await backfillCatalogLogos(db), 0);
      expect((await stored('a')).logoKey, isNull);
      expect((await stored('a')).categoryId, isNull);
    });

    test('never overrides a logo that is already set', () async {
      await db.recurringItemsDao.insertItem(
        _item('a', 'Netflix', logoKey: 'spotify'),
      );
      expect(await backfillCatalogLogos(db), 0);
      expect((await stored('a')).logoKey, 'spotify');
    });

    test('keeps a category the user already chose', () async {
      await db.recurringItemsDao.insertItem(
        _item('a', 'Netflix', categoryId: 'health'),
      );
      await backfillCatalogLogos(db);
      expect((await stored('a')).logoKey, 'netflix');
      expect((await stored('a')).categoryId, 'health');
    });

    test('changes only the logo and category', () async {
      await db.recurringItemsDao.insertItem(_item('a', 'Netflix'));
      final before = await stored('a');
      await backfillCatalogLogos(db);
      final after = await stored('a');
      expect(after.name, before.name);
      expect(after.amount, before.amount);
      expect(after.nextDueDate, before.nextDueDate);
      expect(after.updatedAt, before.updatedAt);
      expect(after.status, before.status);
    });

    test('is safe to run again', () async {
      await db.recurringItemsDao.insertItem(_item('a', 'Netflix'));
      expect(await backfillCatalogLogos(db), 1);
      expect(await backfillCatalogLogos(db), 0);
    });

    test('an empty database is fine', () async {
      expect(await backfillCatalogLogos(db), 0);
    });
  });

  group('at app start', () {
    tracklyTest('an existing item named like a catalog service gets its logo', (
      tester,
    ) async {
      final db = await pumpTrackly(tester, items: [testItem('Netflix')]);

      final stored = await tester.runAsync(
        () => db.recurringItemsDao.getById('Netflix'),
      );
      expect(stored!.logoKey, 'netflix');
      expect(
        find.descendant(
          of: find.byType(ServiceIcon),
          matching: find.byType(SvgPicture),
        ),
        findsOneWidget,
      );
    });
  });
}

/// How many pixels are not (almost) white: the logo's ink.
int _drawnPixels(Uint8List rgba) {
  var count = 0;
  for (var i = 0; i < rgba.length; i += 4) {
    final r = rgba[i], g = rgba[i + 1], b = rgba[i + 2];
    if (r < 235 || g < 235 || b < 235) count++;
  }
  return count;
}
