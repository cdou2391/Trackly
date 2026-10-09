/// A common service offered by Quick Add search.
///
/// Keys are permanent identifiers stored in `recurring_items.logo_key`; never
/// rename one once released. Until a logo asset is added for a service, the UI
/// shows a monogram tile.
class CatalogService {
  const CatalogService({
    required this.key,
    required this.name,
    required this.categoryId,
  });

  final String key;
  final String name;

  /// Id of a seeded category (see `systemCategories`).
  final String categoryId;
}

const serviceCatalog = <CatalogService>[
  CatalogService(key: 'netflix', name: 'Netflix', categoryId: 'entertainment'),
  CatalogService(key: 'spotify', name: 'Spotify', categoryId: 'entertainment'),
  CatalogService(
    key: 'youtube_premium',
    name: 'YouTube Premium',
    categoryId: 'entertainment',
  ),
  CatalogService(
    key: 'apple_music',
    name: 'Apple Music',
    categoryId: 'entertainment',
  ),
  CatalogService(
    key: 'amazon_prime',
    name: 'Amazon Prime',
    categoryId: 'entertainment',
  ),
  CatalogService(
    key: 'disney_plus',
    name: 'Disney+',
    categoryId: 'entertainment',
  ),
  CatalogService(key: 'google_one', name: 'Google One', categoryId: 'software'),
  CatalogService(key: 'icloud_plus', name: 'iCloud+', categoryId: 'software'),
  CatalogService(
    key: 'microsoft_365',
    name: 'Microsoft 365',
    categoryId: 'software',
  ),
  CatalogService(key: 'adobe', name: 'Adobe', categoryId: 'software'),
  CatalogService(
    key: 'chatgpt_plus',
    name: 'ChatGPT Plus',
    categoryId: 'software',
  ),
  CatalogService(key: 'dropbox', name: 'Dropbox', categoryId: 'software'),
  CatalogService(key: 'canva', name: 'Canva', categoryId: 'software'),
  CatalogService(key: 'notion', name: 'Notion', categoryId: 'software'),
];

final serviceCatalogByKey = {
  for (final service in serviceCatalog) service.key: service,
};

/// Services whose name contains [query] (case-insensitive), prefix matches
/// first. Returns nothing for a blank query.
List<CatalogService> searchServiceCatalog(String query, {int limit = 4}) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return const [];

  final prefix = <CatalogService>[];
  final contains = <CatalogService>[];
  for (final service in serviceCatalog) {
    final name = service.name.toLowerCase();
    if (name.startsWith(q)) {
      prefix.add(service);
    } else if (name.contains(q)) {
      contains.add(service);
    }
  }
  return [...prefix, ...contains].take(limit).toList();
}
