import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:trackly/core/database/tables/categories_table.dart';
import 'package:trackly/features/subscriptions/domain/recurring_enums.dart';
import 'package:trackly/features/subscriptions/domain/service_catalog.dart';

void main() {
  test('catalog keys are unique and lowercase', () {
    final keys = [for (final s in serviceCatalog) s.key];
    expect(keys.toSet(), hasLength(keys.length));
    expect(keys.every((k) => k == k.toLowerCase() && !k.contains(' ')), isTrue);
  });

  test('names are unique, so a typed name finds exactly one service', () {
    final names = [for (final s in serviceCatalog) s.name.toLowerCase()];
    expect(names.toSet(), hasLength(names.length));
  });

  group('bills', () {
    final bills = serviceCatalog
        .where((s) => s.type == RecurringItemType.bill)
        .toList();

    test('the everyday ones are there, as bills', () {
      expect(
        bills.map((s) => s.name),
        containsAll([
          'Rent',
          'Water',
          'Electricity',
          'Gas',
          'Internet',
          'Mobile phone',
          'Mortgage',
          'Car insurance',
        ]),
      );
    });

    test('brands stay subscriptions and bills carry no logo', () {
      expect(
        serviceCatalogByKey['netflix']!.type,
        RecurringItemType.subscription,
      );
      expect(bills.every((s) => s.logoAsset == null), isTrue);
    });

    test('each sits in the category a person would look for it in', () {
      String category(String key) => serviceCatalogByKey[key]!.categoryId;
      expect(category('electricity'), 'utilities');
      expect(category('water'), 'utilities');
      expect(category('rent'), 'housing');
      expect(category('car_insurance'), 'insurance');
      expect(category('tuition'), 'education');
    });

    test('search finds them by a part of the name', () {
      expect(searchServiceCatalog('electric').map((s) => s.key), [
        'electricity',
      ]);
      expect(searchServiceCatalog('rent').first.key, 'rent');
      expect(findServiceByName('  water ')!.type, RecurringItemType.bill);
    });
  });

  test('every catalog service points at a seeded category', () {
    final ids = {for (final c in systemCategories) c.id};
    for (final service in serviceCatalog) {
      expect(ids, contains(service.categoryId), reason: service.key);
    }
  });

  test('search is case-insensitive and prefix matches come first', () {
    final results = searchServiceCatalog('NET');
    expect(results.first.key, 'netflix');
    expect(searchServiceCatalog('prime').map((s) => s.key), ['amazon_prime']);
    expect(searchServiceCatalog('youtube').map((s) => s.key), [
      'youtube_premium',
      'youtube_tv',
    ]);
  });

  test('prefix matches rank above substring matches', () {
    final keys = searchServiceCatalog('a').map((s) => s.name).toList();
    expect(keys.first.toLowerCase().startsWith('a'), isTrue);
  });

  test('blank or unmatched queries return nothing', () {
    expect(searchServiceCatalog(''), isEmpty);
    expect(searchServiceCatalog('   '), isEmpty);
    expect(searchServiceCatalog('zzzz'), isEmpty);
  });

  test('results are capped', () {
    expect(searchServiceCatalog('e', limit: 3).length, lessThanOrEqualTo(3));
  });

  test('catalog lookup by key', () {
    expect(serviceCatalogByKey['spotify']!.name, 'Spotify');
    expect(serviceCatalogByKey['nope'], isNull);
  });

  group('logos', () {
    final withLogo = serviceCatalog.where((s) => s.logoAsset != null).toList();
    final withoutLogo = serviceCatalog
        .where((s) => s.logoAsset == null)
        .toList();

    test(
      'every logo file exists in the bundled folder and is named by its key',
      () {
        for (final service in withLogo) {
          expect(service.logoAsset, 'assets/logos/${service.key}.svg');
          expect(
            File(service.logoAsset!).existsSync(),
            isTrue,
            reason: service.key,
          );
        }
      },
    );

    test('no file in the folder is left unused', () {
      final files = Directory('assets/logos')
          .listSync()
          .whereType<File>()
          .map((f) => f.uri.pathSegments.last)
          .where((n) => n.endsWith('.svg'))
          .toSet();
      expect(files, {for (final s in withLogo) '${s.key}.svg'});
    });

    test('files are real SVGs with nothing that could run or phone home', () {
      for (final service in withLogo) {
        final svg = File(service.logoAsset!).readAsStringSync();
        expect(svg.contains('<svg'), isTrue, reason: service.key);
        for (final bad in [
          '<script',
          'foreignObject',
          '<image',
          'onload',
          'onclick',
          'javascript:',
        ]) {
          expect(svg.contains(bad), isFalse, reason: '${service.key}: $bad');
        }
        // No links to anything outside the file.
        expect(
          RegExp(r"""(?:href|src)=["'](?!#)""").hasMatch(svg),
          isFalse,
          reason: service.key,
        );
        expect(svg.length, lessThan(20000), reason: '${service.key} is big');
      }
    });

    test('the requested platforms have logos; some still do not', () {
      expect(
        withLogo.map((s) => s.key),
        containsAll([
          'netflix',
          'youtube_premium',
          'spotify',
          'apple_music',
          'apple_tv_plus',
          'max',
          'paramount_plus',
          'microsoft_365',
          'google_one',
          'icloud_plus',
          'chatgpt_plus',
          'adobe',
          // Added with the bigger list.
          'github',
          'slack',
          'zoom',
          'figma',
          'notion',
          'dropbox',
          'claude_pro',
          'duolingo',
        ]),
      );
      expect(withLogo, hasLength(56));
      // Not in the open collections, or unreadable at icon size; they show the
      // Trackly mark.
      expect(
        withoutLogo.map((s) => s.key),
        containsAll(['amazon_prime', 'disney_plus', 'hulu', 'canva', 'dazn']),
      );
    });

    test('generic entries never have a logo', () {
      final generic = serviceCatalog.where((s) => s.isGeneric);
      expect(generic.every((s) => s.logoAsset == null), isTrue);
      expect(
        generic.map((s) => s.key),
        containsAll(['rent', 'electricity', 'gym_membership', 'domain_name']),
      );
      expect(serviceCatalogByKey['netflix']!.isGeneric, isFalse);
    });

    test('black marks are exactly the logos whose only color is black', () {
      final flagged = {
        for (final s in withLogo)
          if (s.blackMark) s.key,
      };
      // Distinct fill colors in each file. Netflix also contains black, but as
      // the square behind its red N, so it must not be inverted.
      final onlyBlack = {
        for (final s in withLogo)
          if (_fills(File(s.logoAsset!).readAsStringSync())
              .difference({'#000000'})
              .isEmpty)
            s.key,
      };
      expect(flagged, {
        'apple_tv_plus',
        'max',
        'chatgpt_plus',
        'apple_arcade',
        'github',
        'new_york_times',
        'peloton',
        'squarespace',
        'tidal',
        'uber_one',
        'medium',
        'midjourney',
      });
      expect(flagged, onlyBlack);
    });

    test('the licenses file credits every logo', () {
      final notice = File('assets/logos/LICENSES.md').readAsStringSync();
      expect(notice, contains('CC0'));
      expect(notice, contains('trademark'));
      for (final service in withLogo) {
        expect(notice, contains('${service.key}.svg'), reason: service.key);
      }
    });
  });

  group('findServiceByName', () {
    test('matches exactly, ignoring case and extra spaces', () {
      expect(findServiceByName('Netflix')!.key, 'netflix');
      expect(findServiceByName('netflix')!.key, 'netflix');
      expect(findServiceByName('  NETFLIX  ')!.key, 'netflix');
      expect(findServiceByName('apple   tv+')!.key, 'apple_tv_plus');
      expect(findServiceByName('Paramount+')!.key, 'paramount_plus');
    });

    test('does not guess at partial or different names', () {
      expect(findServiceByName('Netflix family'), isNull);
      expect(findServiceByName('Net'), isNull);
      expect(findServiceByName('Gym'), isNull);
      expect(findServiceByName(''), isNull);
    });
  });
}

/// The distinct fill colors set in an SVG (ignoring `none`).
Set<String> _fills(String svg) => {
  for (final m in RegExp(r'fill="([^"]+)"').allMatches(svg))
    if (m.group(1) != 'none') m.group(1)!.toLowerCase(),
};
