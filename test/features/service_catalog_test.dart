import 'package:flutter_test/flutter_test.dart';
import 'package:trackly/core/database/tables/categories_table.dart';
import 'package:trackly/features/subscriptions/domain/service_catalog.dart';

void main() {
  test('catalog keys are unique and lowercase', () {
    final keys = [for (final s in serviceCatalog) s.key];
    expect(keys.toSet(), hasLength(keys.length));
    expect(keys.every((k) => k == k.toLowerCase() && !k.contains(' ')), isTrue);
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
    expect(searchServiceCatalog('youtube').map((s) => s.key),
        ['youtube_premium']);
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
}
