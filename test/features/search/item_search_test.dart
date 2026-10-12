import 'package:flutter_test/flutter_test.dart';
import 'package:trackly/features/search/application/item_search.dart';
import 'package:trackly/features/subscriptions/domain/recurring_enums.dart';
import 'package:trackly/features/subscriptions/domain/recurring_item.dart';

final _now = DateTime(2026, 10, 9);

RecurringItem item(
  String name, {
  String? category,
  String? notes,
  ItemStatus status = ItemStatus.active,
  DateTime? due,
}) {
  return RecurringItem(
    id: name,
    name: name,
    type: RecurringItemType.subscription,
    amount: 10,
    currencyCode: 'USD',
    frequency: BillingFrequency.monthly,
    startDate: DateTime(2026, 1, 15),
    nextDueDate: due ?? DateTime(2026, 10, 20),
    status: status,
    categoryId: category,
    notes: notes,
    createdAt: _now,
    updatedAt: _now,
  );
}

String? _categories(String? id) => switch (id) {
  'ent' => 'Entertainment',
  'soft' => 'Software',
  _ => null,
};

List<String> find(List<RecurringItem> items, String query) => [
  for (final i in searchItems(items, query, categoryNameOf: _categories))
    i.name,
];

void main() {
  group('foldForSearch', () {
    test('lowercases and removes accents', () {
      expect(foldForSearch('Café ÉCOLE Zażółć'), 'cafe ecole zazolc');
      expect(foldForSearch('Łódź ø đ'), 'lodz o d');
    });

    test('leaves other scripts and digits alone', () {
      expect(foldForSearch('Adobe 365 音楽'), 'adobe 365 音楽');
    });
  });

  group('searchTerms', () {
    test('splits on any whitespace and drops empties', () {
      expect(searchTerms('  Net   flix\tHD '), ['net', 'flix', 'hd']);
      expect(searchTerms('   '), isEmpty);
      expect(searchTerms(''), isEmpty);
    });
  });

  group('searchItems', () {
    final items = [
      item('Netflix', category: 'ent'),
      item('Spotify', category: 'ent', notes: 'Family plan'),
      item('Adobe Creative Cloud', category: 'soft'),
      item('Notion', category: 'soft', notes: 'Team workspace'),
      item('Gym'),
    ];

    test('an empty query matches nothing', () {
      expect(find(items, ''), isEmpty);
      expect(find(items, '   '), isEmpty);
    });

    test('matches part of a name, ignoring case', () {
      expect(find(items, 'FLIX'), ['Netflix']);
      expect(find(items, 'spot'), ['Spotify']);
    });

    test('matches the category name', () {
      expect(find(items, 'entertain'), ['Netflix', 'Spotify']);
      expect(find(items, 'software'), ['Adobe Creative Cloud', 'Notion']);
    });

    test('matches notes', () {
      expect(find(items, 'family'), ['Spotify']);
      expect(find(items, 'workspace'), ['Notion']);
    });

    test('every word must match, in any order', () {
      expect(find(items, 'cloud adobe'), ['Adobe Creative Cloud']);
      expect(find(items, 'notion team'), ['Notion']);
      expect(find(items, 'notion family'), isEmpty);
    });

    test('no match gives an empty list', () {
      expect(find(items, 'hulu'), isEmpty);
    });

    test('accents are ignored on both sides', () {
      final accented = [item('Café Club'), item('Cafe Nero')];
      expect(find(accented, 'cafe'), ['Cafe Nero', 'Café Club']);
      expect(find(accented, 'café nero'), ['Cafe Nero']);
    });

    test('names that start with the query come first', () {
      final list = [
        item('My Notion', due: DateTime(2026, 10, 10)),
        item('Notes', category: 'soft', due: DateTime(2026, 10, 30)),
        item('Other', notes: 'not on', due: DateTime(2026, 10, 11)),
        item('Notion', due: DateTime(2026, 10, 25)),
      ];
      // "notion" starts Notion and is inside My Notion; Notes lacks it.
      expect(find(list, 'notion'), ['Notion', 'My Notion']);
      // "not" starts Notion and Notes (soonest due first), is inside My
      // Notion, and reaches Other only through its notes.
      expect(find(list, 'not'), ['Notion', 'Notes', 'My Notion', 'Other']);
    });

    test('live items come before paused and cancelled ones', () {
      final list = [
        item('Plan C', status: ItemStatus.cancelled),
        item('Plan B', status: ItemStatus.paused),
        item('Plan A'),
      ];
      expect(find(list, 'plan'), ['Plan A', 'Plan B', 'Plan C']);
    });

    test('paused and cancelled items can be found', () {
      final list = [
        item('Old gym', status: ItemStatus.cancelled),
        item('Paused app', status: ItemStatus.paused),
      ];
      expect(find(list, 'gym'), ['Old gym']);
      expect(find(list, 'app'), ['Paused app']);
    });

    test('ties go to the soonest due date, then the name', () {
      final list = [
        item('Plan Beta', due: DateTime(2026, 10, 12)),
        item('Plan Alpha', due: DateTime(2026, 10, 12)),
        item('Plan Gamma', due: DateTime(2026, 10, 11)),
      ];
      expect(find(list, 'plan'), ['Plan Gamma', 'Plan Alpha', 'Plan Beta']);
    });

    test('regex characters in the query are plain text', () {
      final list = [item('C++ Club'), item('Plain')];
      expect(find(list, 'c++'), ['C++ Club']);
      expect(find(list, '.*'), isEmpty);
      expect(find(list, '('), isEmpty);
    });
  });
}
