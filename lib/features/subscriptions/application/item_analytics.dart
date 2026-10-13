import '../domain/recurring_item.dart';

/// The structured facts about [item] that analytics events carry.
///
/// Never the name, notes or any other text the person typed.
Map<String, Object> itemAnalyticsParameters(RecurringItem item) => {
  'item_type': item.type.name,
  'frequency': item.frequency.name,
  'currency': item.currencyCode,
  'is_trial': item.isTrial,
};
