/// A common service offered by Quick Add search.
///
/// Keys are permanent identifiers stored in `recurring_items.logo_key`; never
/// rename one once released. The database stores only the key; the logo file
/// is bundled with the app and found through this catalog. Services without a
/// [logoAsset] show a letter tile.
class CatalogService {
  const CatalogService({
    required this.key,
    required this.name,
    required this.categoryId,
    this.logoAsset,
    this.blackMark = false,
  });

  final String key;
  final String name;

  /// Id of a seeded category (see `systemCategories`).
  final String categoryId;

  /// Bundled SVG, for example `assets/logos/netflix.svg`. Null until a logo is
  /// added. See `assets/logos/LICENSES.md` for sources and trademark notes.
  final String? logoAsset;

  /// The logo is a single black mark, which would disappear on a dark page, so
  /// it is drawn white in the dark theme.
  final bool blackMark;
}

const _logos = 'assets/logos';

const serviceCatalog = <CatalogService>[
  CatalogService(
    key: 'netflix',
    name: 'Netflix',
    categoryId: 'entertainment',
    logoAsset: '$_logos/netflix.svg',
  ),
  CatalogService(
    key: 'amazon_prime',
    name: 'Amazon Prime',
    categoryId: 'entertainment',
  ),
  CatalogService(
    key: 'youtube_premium',
    name: 'YouTube Premium',
    categoryId: 'entertainment',
    logoAsset: '$_logos/youtube_premium.svg',
  ),
  CatalogService(
    key: 'spotify',
    name: 'Spotify',
    categoryId: 'entertainment',
    logoAsset: '$_logos/spotify.svg',
  ),
  CatalogService(
    key: 'disney_plus',
    name: 'Disney+',
    categoryId: 'entertainment',
  ),
  CatalogService(
    key: 'apple_music',
    name: 'Apple Music',
    categoryId: 'entertainment',
    logoAsset: '$_logos/apple_music.svg',
  ),
  CatalogService(
    key: 'apple_tv_plus',
    name: 'Apple TV+',
    categoryId: 'entertainment',
    logoAsset: '$_logos/apple_tv_plus.svg',
    blackMark: true,
  ),
  CatalogService(
    key: 'max',
    name: 'Max',
    categoryId: 'entertainment',
    logoAsset: '$_logos/max.svg',
    blackMark: true,
  ),
  CatalogService(key: 'hulu', name: 'Hulu', categoryId: 'entertainment'),
  CatalogService(
    key: 'paramount_plus',
    name: 'Paramount+',
    categoryId: 'entertainment',
    logoAsset: '$_logos/paramount_plus.svg',
  ),
  CatalogService(
    key: 'microsoft_365',
    name: 'Microsoft 365',
    categoryId: 'software',
    logoAsset: '$_logos/microsoft_365.svg',
  ),
  CatalogService(
    key: 'google_one',
    name: 'Google One',
    categoryId: 'software',
    logoAsset: '$_logos/google_one.svg',
  ),
  CatalogService(
    key: 'icloud_plus',
    name: 'iCloud+',
    categoryId: 'software',
    logoAsset: '$_logos/icloud_plus.svg',
  ),
  CatalogService(
    key: 'chatgpt_plus',
    name: 'ChatGPT Plus',
    categoryId: 'software',
    logoAsset: '$_logos/chatgpt_plus.svg',
    blackMark: true,
  ),
  CatalogService(
    key: 'adobe',
    name: 'Adobe',
    categoryId: 'software',
    logoAsset: '$_logos/adobe.svg',
  ),
  CatalogService(key: 'dropbox', name: 'Dropbox', categoryId: 'software'),
  CatalogService(key: 'canva', name: 'Canva', categoryId: 'software'),
  CatalogService(key: 'notion', name: 'Notion', categoryId: 'software'),
];

final serviceCatalogByKey = {
  for (final service in serviceCatalog) service.key: service,
};

String _normalize(String text) =>
    text.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

final _catalogByName = {
  for (final service in serviceCatalog) _normalize(service.name): service,
};

/// The catalog service whose name is exactly [name] (ignoring case, spacing at
/// the ends and repeated spaces), or null for a custom name.
///
/// Lets a typed "netflix" get the Netflix logo without picking the suggestion.
CatalogService? findServiceByName(String name) =>
    _catalogByName[_normalize(name)];

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
