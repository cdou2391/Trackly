import 'recurring_enums.dart';

/// A common service or bill offered by Quick Add search.
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
    this.type = RecurringItemType.subscription,
    this.generic = false,
    this.logoAsset,
    this.blackMark = false,
  });

  final String key;
  final String name;

  /// Id of a seeded category (see `systemCategories`).
  final String categoryId;

  /// A kind of thing rather than a brand ("Gym membership", "Domain name"). It
  /// has no logo and is drawn with its category icon, not the Trackly mark.
  /// Every bill is generic too.
  final bool generic;

  /// Whether picking it adds a subscription (a brand) or a bill (Rent, Water,
  /// Electricity and the like).
  final RecurringItemType type;

  /// Drawn with its category icon instead of a logo or the Trackly mark.
  bool get isGeneric => generic || type == RecurringItemType.bill;

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
  CatalogService(
    key: 'dropbox',
    name: 'Dropbox',
    categoryId: 'software',
    logoAsset: '$_logos/dropbox.svg',
  ),
  CatalogService(key: 'canva', name: 'Canva', categoryId: 'software'),
  CatalogService(
    key: 'notion',
    name: 'Notion',
    categoryId: 'software',
    logoAsset: '$_logos/notion.svg',
  ),
  CatalogService(key: 'peacock', name: 'Peacock', categoryId: 'entertainment'),
  CatalogService(
    key: 'crunchyroll',
    name: 'Crunchyroll',
    categoryId: 'entertainment',
    logoAsset: '$_logos/crunchyroll.svg',
  ),
  CatalogService(key: 'dazn', name: 'DAZN', categoryId: 'entertainment'),
  CatalogService(key: 'espn_plus', name: 'ESPN+', categoryId: 'entertainment'),
  CatalogService(
    key: 'youtube_tv',
    name: 'YouTube TV',
    categoryId: 'entertainment',
  ),
  CatalogService(
    key: 'audible',
    name: 'Audible',
    categoryId: 'entertainment',
    logoAsset: '$_logos/audible.svg',
  ),
  CatalogService(
    key: 'deezer',
    name: 'Deezer',
    categoryId: 'entertainment',
    logoAsset: '$_logos/deezer.svg',
  ),
  CatalogService(
    key: 'tidal',
    name: 'Tidal',
    categoryId: 'entertainment',
    logoAsset: '$_logos/tidal.svg',
    blackMark: true,
  ),
  CatalogService(
    key: 'xbox_game_pass',
    name: 'Xbox Game Pass',
    categoryId: 'entertainment',
  ),
  CatalogService(
    key: 'playstation_plus',
    name: 'PlayStation Plus',
    categoryId: 'entertainment',
    logoAsset: '$_logos/playstation_plus.svg',
  ),
  CatalogService(
    key: 'nintendo_switch_online',
    name: 'Nintendo Switch Online',
    categoryId: 'entertainment',
  ),
  CatalogService(
    key: 'apple_arcade',
    name: 'Apple Arcade',
    categoryId: 'entertainment',
    logoAsset: '$_logos/apple_arcade.svg',
    blackMark: true,
  ),
  CatalogService(
    key: 'twitch',
    name: 'Twitch',
    categoryId: 'entertainment',
    logoAsset: '$_logos/twitch.svg',
  ),
  CatalogService(
    key: 'kindle_unlimited',
    name: 'Kindle Unlimited',
    categoryId: 'entertainment',
  ),
  CatalogService(key: 'showmax', name: 'Showmax', categoryId: 'entertainment'),
  CatalogService(key: 'dstv', name: 'DStv', categoryId: 'entertainment'),
  CatalogService(
    key: 'canal_plus',
    name: 'Canal+',
    categoryId: 'entertainment',
  ),
  CatalogService(
    key: 'startimes',
    name: 'StarTimes',
    categoryId: 'entertainment',
  ),
  CatalogService(
    key: 'claude_pro',
    name: 'Claude Pro',
    categoryId: 'software',
    logoAsset: '$_logos/claude_pro.svg',
  ),
  CatalogService(
    key: 'perplexity_pro',
    name: 'Perplexity Pro',
    categoryId: 'software',
    logoAsset: '$_logos/perplexity_pro.svg',
  ),
  CatalogService(
    key: 'midjourney',
    name: 'Midjourney',
    categoryId: 'software',
    logoAsset: '$_logos/midjourney.svg',
    blackMark: true,
  ),
  CatalogService(
    key: 'github',
    name: 'GitHub',
    categoryId: 'software',
    logoAsset: '$_logos/github.svg',
    blackMark: true,
  ),
  CatalogService(
    key: 'slack',
    name: 'Slack',
    categoryId: 'software',
    logoAsset: '$_logos/slack.svg',
  ),
  CatalogService(
    key: 'zoom',
    name: 'Zoom',
    categoryId: 'software',
    logoAsset: '$_logos/zoom.svg',
  ),
  CatalogService(
    key: 'figma',
    name: 'Figma',
    categoryId: 'software',
    logoAsset: '$_logos/figma.svg',
  ),
  CatalogService(
    key: '1password',
    name: '1Password',
    categoryId: 'software',
    logoAsset: '$_logos/1password.svg',
  ),
  CatalogService(
    key: 'nordvpn',
    name: 'NordVPN',
    categoryId: 'software',
    logoAsset: '$_logos/nordvpn.svg',
  ),
  CatalogService(
    key: 'expressvpn',
    name: 'ExpressVPN',
    categoryId: 'software',
    logoAsset: '$_logos/expressvpn.svg',
  ),
  CatalogService(
    key: 'proton',
    name: 'Proton',
    categoryId: 'software',
    logoAsset: '$_logos/proton.svg',
  ),
  CatalogService(
    key: 'grammarly',
    name: 'Grammarly',
    categoryId: 'software',
    logoAsset: '$_logos/grammarly.svg',
  ),
  CatalogService(
    key: 'evernote',
    name: 'Evernote',
    categoryId: 'software',
    logoAsset: '$_logos/evernote.svg',
  ),
  CatalogService(
    key: 'todoist',
    name: 'Todoist',
    categoryId: 'software',
    logoAsset: '$_logos/todoist.svg',
  ),
  CatalogService(
    key: 'google_workspace',
    name: 'Google Workspace',
    categoryId: 'software',
  ),
  CatalogService(key: 'apple_one', name: 'Apple One', categoryId: 'software'),
  CatalogService(
    key: 'duolingo',
    name: 'Duolingo',
    categoryId: 'education',
    logoAsset: '$_logos/duolingo.svg',
  ),
  CatalogService(
    key: 'coursera',
    name: 'Coursera',
    categoryId: 'education',
    logoAsset: '$_logos/coursera.svg',
  ),
  CatalogService(
    key: 'udemy',
    name: 'Udemy',
    categoryId: 'education',
    logoAsset: '$_logos/udemy.svg',
  ),
  CatalogService(
    key: 'linkedin_learning',
    name: 'LinkedIn Learning',
    categoryId: 'education',
    logoAsset: '$_logos/linkedin_learning.svg',
  ),
  CatalogService(
    key: 'skillshare',
    name: 'Skillshare',
    categoryId: 'education',
    logoAsset: '$_logos/skillshare.svg',
  ),
  CatalogService(
    key: 'masterclass',
    name: 'MasterClass',
    categoryId: 'education',
  ),
  CatalogService(key: 'babbel', name: 'Babbel', categoryId: 'education'),
  CatalogService(key: 'calm', name: 'Calm', categoryId: 'health'),
  CatalogService(
    key: 'headspace',
    name: 'Headspace',
    categoryId: 'health',
    logoAsset: '$_logos/headspace.svg',
  ),
  CatalogService(
    key: 'gym_membership',
    name: 'Gym membership',
    categoryId: 'fitness',
    generic: true,
  ),
  CatalogService(
    key: 'strava',
    name: 'Strava',
    categoryId: 'fitness',
    logoAsset: '$_logos/strava.svg',
  ),
  CatalogService(
    key: 'peloton',
    name: 'Peloton',
    categoryId: 'fitness',
    logoAsset: '$_logos/peloton.svg',
    blackMark: true,
  ),
  CatalogService(
    key: 'fitbit_premium',
    name: 'Fitbit Premium',
    categoryId: 'fitness',
    logoAsset: '$_logos/fitbit_premium.svg',
  ),
  CatalogService(
    key: 'apple_fitness_plus',
    name: 'Apple Fitness+',
    categoryId: 'fitness',
  ),
  CatalogService(
    key: 'shopify',
    name: 'Shopify',
    categoryId: 'business',
    logoAsset: '$_logos/shopify.svg',
  ),
  CatalogService(
    key: 'squarespace',
    name: 'Squarespace',
    categoryId: 'business',
    logoAsset: '$_logos/squarespace.svg',
    blackMark: true,
  ),
  CatalogService(
    key: 'wix',
    name: 'Wix',
    categoryId: 'business',
    logoAsset: '$_logos/wix.svg',
  ),
  CatalogService(
    key: 'godaddy',
    name: 'GoDaddy',
    categoryId: 'business',
    logoAsset: '$_logos/godaddy.svg',
  ),
  CatalogService(
    key: 'mailchimp',
    name: 'Mailchimp',
    categoryId: 'business',
    logoAsset: '$_logos/mailchimp.svg',
  ),
  CatalogService(
    key: 'quickbooks',
    name: 'QuickBooks',
    categoryId: 'business',
    logoAsset: '$_logos/quickbooks.svg',
  ),
  CatalogService(
    key: 'domain_name',
    name: 'Domain name',
    categoryId: 'business',
    generic: true,
  ),
  CatalogService(
    key: 'web_hosting',
    name: 'Web hosting',
    categoryId: 'business',
    generic: true,
  ),
  CatalogService(
    key: 'uber_one',
    name: 'Uber One',
    categoryId: 'transport',
    logoAsset: '$_logos/uber_one.svg',
    blackMark: true,
  ),
  CatalogService(
    key: 'lyft_pink',
    name: 'Lyft Pink',
    categoryId: 'transport',
    logoAsset: '$_logos/lyft_pink.svg',
  ),
  CatalogService(
    key: 'new_york_times',
    name: 'The New York Times',
    categoryId: 'other',
    logoAsset: '$_logos/new_york_times.svg',
    blackMark: true,
  ),
  CatalogService(
    key: 'medium',
    name: 'Medium',
    categoryId: 'other',
    logoAsset: '$_logos/medium.svg',
    blackMark: true,
  ),
  CatalogService(
    key: 'patreon',
    name: 'Patreon',
    categoryId: 'other',
    logoAsset: '$_logos/patreon.svg',
  ),
  CatalogService(
    key: 'substack',
    name: 'Substack',
    categoryId: 'other',
    logoAsset: '$_logos/substack.svg',
  ),
  CatalogService(key: 'walmart_plus', name: 'Walmart+', categoryId: 'other'),
  CatalogService(
    key: 'costco_membership',
    name: 'Costco membership',
    categoryId: 'other',
  ),

  // Bills: things you owe on a schedule rather than services you subscribe to.
  CatalogService(
    key: 'electricity',
    name: 'Electricity',
    categoryId: 'utilities',
    type: RecurringItemType.bill,
  ),
  CatalogService(
    key: 'water',
    name: 'Water',
    categoryId: 'utilities',
    type: RecurringItemType.bill,
  ),
  CatalogService(
    key: 'gas',
    name: 'Gas',
    categoryId: 'utilities',
    type: RecurringItemType.bill,
  ),
  CatalogService(
    key: 'internet',
    name: 'Internet',
    categoryId: 'utilities',
    type: RecurringItemType.bill,
  ),
  CatalogService(
    key: 'mobile_phone',
    name: 'Mobile phone',
    categoryId: 'utilities',
    type: RecurringItemType.bill,
  ),
  CatalogService(
    key: 'landline',
    name: 'Landline',
    categoryId: 'utilities',
    type: RecurringItemType.bill,
  ),
  CatalogService(
    key: 'cable_tv',
    name: 'Cable TV',
    categoryId: 'utilities',
    type: RecurringItemType.bill,
  ),
  CatalogService(
    key: 'waste_collection',
    name: 'Waste collection',
    categoryId: 'utilities',
    type: RecurringItemType.bill,
  ),
  CatalogService(
    key: 'sewer',
    name: 'Sewer',
    categoryId: 'utilities',
    type: RecurringItemType.bill,
  ),
  CatalogService(
    key: 'heating',
    name: 'Heating',
    categoryId: 'utilities',
    type: RecurringItemType.bill,
  ),
  CatalogService(
    key: 'rent',
    name: 'Rent',
    categoryId: 'housing',
    type: RecurringItemType.bill,
  ),
  CatalogService(
    key: 'mortgage',
    name: 'Mortgage',
    categoryId: 'housing',
    type: RecurringItemType.bill,
  ),
  CatalogService(
    key: 'property_tax',
    name: 'Property tax',
    categoryId: 'housing',
    type: RecurringItemType.bill,
  ),
  CatalogService(
    key: 'hoa_fees',
    name: 'HOA fees',
    categoryId: 'housing',
    type: RecurringItemType.bill,
  ),
  CatalogService(
    key: 'service_charge',
    name: 'Service charge',
    categoryId: 'housing',
    type: RecurringItemType.bill,
  ),
  CatalogService(
    key: 'storage_unit',
    name: 'Storage unit',
    categoryId: 'housing',
    type: RecurringItemType.bill,
  ),
  CatalogService(
    key: 'health_insurance',
    name: 'Health insurance',
    categoryId: 'insurance',
    type: RecurringItemType.bill,
  ),
  CatalogService(
    key: 'car_insurance',
    name: 'Car insurance',
    categoryId: 'insurance',
    type: RecurringItemType.bill,
  ),
  CatalogService(
    key: 'home_insurance',
    name: 'Home insurance',
    categoryId: 'insurance',
    type: RecurringItemType.bill,
  ),
  CatalogService(
    key: 'life_insurance',
    name: 'Life insurance',
    categoryId: 'insurance',
    type: RecurringItemType.bill,
  ),
  CatalogService(
    key: 'renters_insurance',
    name: 'Renters insurance',
    categoryId: 'insurance',
    type: RecurringItemType.bill,
  ),
  CatalogService(
    key: 'travel_insurance',
    name: 'Travel insurance',
    categoryId: 'insurance',
    type: RecurringItemType.bill,
  ),
  CatalogService(
    key: 'car_loan',
    name: 'Car loan',
    categoryId: 'transport',
    type: RecurringItemType.bill,
  ),
  CatalogService(
    key: 'parking',
    name: 'Parking',
    categoryId: 'transport',
    type: RecurringItemType.bill,
  ),
  CatalogService(
    key: 'transport_pass',
    name: 'Transport pass',
    categoryId: 'transport',
    type: RecurringItemType.bill,
  ),
  CatalogService(
    key: 'school_fees',
    name: 'School fees',
    categoryId: 'education',
    type: RecurringItemType.bill,
  ),
  CatalogService(
    key: 'tuition',
    name: 'Tuition',
    categoryId: 'education',
    type: RecurringItemType.bill,
  ),
  CatalogService(
    key: 'childcare',
    name: 'Childcare',
    categoryId: 'other',
    type: RecurringItemType.bill,
  ),
  CatalogService(
    key: 'student_loan',
    name: 'Student loan',
    categoryId: 'other',
    type: RecurringItemType.bill,
  ),
  CatalogService(
    key: 'personal_loan',
    name: 'Personal loan',
    categoryId: 'other',
    type: RecurringItemType.bill,
  ),
  CatalogService(
    key: 'credit_card',
    name: 'Credit card',
    categoryId: 'other',
    type: RecurringItemType.bill,
  ),
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
