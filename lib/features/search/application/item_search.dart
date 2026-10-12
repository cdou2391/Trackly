import '../../subscriptions/domain/recurring_enums.dart';
import '../../subscriptions/domain/recurring_item.dart';

const _accented =
    'àáâãäåāăąçćčďđèéêëēĕėęěğìíîïĩīĭįıłńñňòóôõöøōŏőŕřśšşșťţțùúûüũūŭůűųýÿźżž';
const _plain =
    'aaaaaaaaaccc'
    'ddeeeeeeeeegiiiiiiiiilnnnooooooooorrssssttt'
    'uuuuuuuuuuyyzzz';

/// Lower case, with common Latin accents removed, so "cafe" finds "Café" and
/// "SPOTIFY" finds "Spotify".
String foldForSearch(String text) {
  final buffer = StringBuffer();
  for (final rune in text.toLowerCase().runes) {
    final char = String.fromCharCode(rune);
    final index = _accented.indexOf(char);
    buffer.write(index >= 0 ? _plain[index] : char);
  }
  return buffer.toString();
}

/// The words of a query: folded, split on whitespace, empty parts dropped.
List<String> searchTerms(String query) => [
  for (final part in foldForSearch(query).split(RegExp(r'\s+')))
    if (part.isNotEmpty) part,
];

/// Items matching [query], best match first.
///
/// Every word of the query must appear somewhere in the item's name, category
/// or notes (in any order). Names that start with the query come first, then
/// names that contain it, then matches in the category or notes; within a
/// group, live items come before paused and cancelled ones, soonest due first.
/// An empty query matches nothing.
///
/// Pure, so it is easy to test. [categoryNameOf] resolves an item's category
/// id to its name.
List<RecurringItem> searchItems(
  Iterable<RecurringItem> items,
  String query, {
  required String? Function(String? categoryId) categoryNameOf,
}) {
  final terms = searchTerms(query);
  if (terms.isEmpty) return const [];

  final scored = <({RecurringItem item, int rank})>[];
  for (final item in items) {
    final name = foldForSearch(item.name);
    final rest = foldForSearch(
      '${categoryNameOf(item.categoryId) ?? ''} ${item.notes ?? ''}',
    );
    final haystack = '$name $rest';
    if (!terms.every(haystack.contains)) continue;

    final folded = terms.join(' ');
    final rank = name.startsWith(folded)
        ? 0
        : terms.every(name.contains)
        ? 1
        : 2;
    scored.add((item: item, rank: rank));
  }

  int status(RecurringItem item) => switch (item.status) {
    ItemStatus.active => 0,
    ItemStatus.paused => 1,
    ItemStatus.cancelled => 2,
  };

  scored.sort((a, b) {
    final byRank = a.rank.compareTo(b.rank);
    if (byRank != 0) return byRank;
    final byStatus = status(a.item).compareTo(status(b.item));
    if (byStatus != 0) return byStatus;
    final byDate = a.item.nextDueDate.compareTo(b.item.nextDueDate);
    return byDate != 0 ? byDate : a.item.name.compareTo(b.item.name);
  });
  return [for (final entry in scored) entry.item];
}
