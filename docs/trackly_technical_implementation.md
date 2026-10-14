# Trackly Technical Implementation

## 1. Product Overview

Trackly is a local-first mobile application for tracking:

- Subscriptions
- Recurring payments
- Recurring bills
- Free trials
- Renewal dates
- Payment history
- Upcoming charges
- Reminder notifications

The application should remain intentionally simple.

The primary user question is:

> What is charging me next, and how much am I spending every month?

Trackly should work without:

- A user account
- A backend
- Bank account integration
- Payment processing
- Cloud sync
- Remote database

All subscription and bill data is stored locally on the device.

---

# 2. Recommended Technology Stack

Use the same core stack as Convertly.

## Application

```text
Flutter
Dart
Material 3
```

## State Management

```text
Riverpod
```

Recommended package:

```yaml
flutter_riverpod:
```

## Navigation

```text
GoRouter
```

Recommended package:

```yaml
go_router:
```

## Local Database

```text
Drift
SQLite
```

Recommended packages:

```yaml
drift:
drift_flutter:
path_provider:
```

Development:

```yaml
drift_dev:
build_runner:
```

## Product Analytics

```text
Firebase Analytics
```

Recommended packages:

```yaml
firebase_core:
firebase_analytics:
```

Firebase Analytics is used for anonymous product usage tracking.

Examples:

- subscription_created
- trial_created
- reminder_enabled
- reminder_opened
- payment_recorded
- subscription_cancelled
- upcoming_screen_opened

## Engineering Observability

```text
Sentry
```

Recommended package:

```yaml
sentry_flutter:
```

Sentry is used for:

- Crashes
- Unexpected exceptions
- Stack traces
- Database errors
- Notification scheduling errors
- Performance diagnostics
- Breadcrumbs

Do not use Sentry as the primary product analytics tool.

## Notifications

Use local notifications.

Recommended package:

```yaml
flutter_local_notifications:
```

Timezone support:

```yaml
timezone:
```

Trackly v1 should not require Firebase Cloud Messaging.

All reminders should be scheduled locally on-device.

## Utilities

Recommended:

```yaml
intl:
uuid:
shared_preferences:
```

Optional later:

```yaml
currency_picker:
share_plus:
```

---

# 3. High-Level Architecture

```text
┌──────────────────────────────────────┐
│               Flutter UI             │
│                                      │
│ Home                                 │
│ Add/Edit Subscription                │
│ Upcoming                             │
│ Calendar                             │
│ Insights                             │
│ History                              │
│ Settings                             │
└─────────────────┬────────────────────┘
                  │
                  ▼
┌──────────────────────────────────────┐
│          Application Layer           │
│                                      │
│ Subscription Controller              │
│ Reminder Controller                  │
│ Payment Controller                   │
│ Insights Controller                  │
└─────────────────┬────────────────────┘
                  │
      ┌───────────┼──────────────┐
      ▼           ▼              ▼
┌──────────┐ ┌────────────┐ ┌──────────────┐
│ Domain   │ │ Drift      │ │ Notification │
│ Logic    │ │ SQLite     │ │ Scheduler    │
└──────────┘ └────────────┘ └──────────────┘

                Telemetry
                    │
          ┌─────────┴─────────┐
          ▼                   ▼
   Firebase Analytics       Sentry
   Product Behaviour        Engineering
```

Trackly remains fully functional offline.

---

# 4. Architectural Principles

## 4.1 Local First

The local database is the source of truth.

No subscription information should require an internet connection.

The following remain local:

- Subscription names
- Prices
- Billing schedules
- Renewal dates
- Trial dates
- Payment history
- Notes
- Reminder configuration

## 4.2 No Account Required

The user should be able to:

```text
Install
→ Open
→ Add first subscription
→ Receive reminders
```

without:

- Signup
- Login
- Email verification
- Cloud account creation

## 4.3 Minimal Data Collection

Firebase and Sentry should only receive structured telemetry necessary to improve the application.

Do not send:

- Raw notes
- Custom subscription names
- Sensitive payment information
- User-entered descriptions
- Full local history

---

# 5. Recommended Project Structure

Use feature-first architecture.

```text
lib/
│
├── main.dart
├── app.dart
│
├── core/
│   │
│   ├── analytics/
│   │   ├── analytics_service.dart
│   │   ├── firebase_analytics_service.dart
│   │   └── analytics_events.dart
│   │
│   ├── config/
│   │   └── app_config.dart
│   │
│   ├── database/
│   │   ├── app_database.dart
│   │   ├── app_database.g.dart
│   │   ├── migrations/
│   │   └── tables/
│   │
│   ├── error/
│   │   └── error_reporter.dart
│   │
│   ├── notifications/
│   │   ├── notification_service.dart
│   │   ├── reminder_scheduler.dart
│   │   └── notification_payload.dart
│   │
│   ├── navigation/
│   │   └── app_router.dart
│   │
│   ├── theme/
│   │   ├── app_theme.dart
│   │   └── app_colors.dart
│   │
│   └── utils/
│       ├── currency_utils.dart
│       ├── date_utils.dart
│       └── recurrence_utils.dart
│
├── features/
│   │
│   ├── home/
│   │   ├── application/
│   │   ├── presentation/
│   │   └── widgets/
│   │
│   ├── subscriptions/
│   │   ├── data/
│   │   ├── domain/
│   │   ├── application/
│   │   └── presentation/
│   │
│   ├── reminders/
│   │   ├── application/
│   │   └── domain/
│   │
│   ├── payments/
│   │   ├── data/
│   │   ├── application/
│   │   └── presentation/
│   │
│   ├── calendar/
│   │   ├── application/
│   │   └── presentation/
│   │
│   ├── insights/
│   │   ├── application/
│   │   └── presentation/
│   │
│   ├── history/
│   │   └── presentation/
│   │
│   └── settings/
│       ├── application/
│       └── presentation/
│
└── shared/
    └── widgets/
```

Do not introduce repository abstractions everywhere unless they genuinely improve testability or decoupling.

Keep the architecture pragmatic.

---

# 6. Primary Domain Model

The central domain model is a recurring obligation.

Use one model to support both subscriptions and recurring bills.

Recommended conceptual model:

```dart
class RecurringItem {
  final String id;
  final String name;
  final RecurringItemType type;

  final double amount;
  final String currencyCode;

  final BillingFrequency frequency;
  final int interval;

  final DateTime startDate;
  final DateTime nextDueDate;

  final ItemStatus status;

  final bool isTrial;
  final DateTime? trialEndDate;

  final bool remindersEnabled;
  final int reminderDaysBefore;

  final String? categoryId;
  final String? notes;

  /// Key into the bundled service catalog (for example 'netflix').
  /// Null for custom services.
  final String? logoKey;

  final DateTime createdAt;
  final DateTime updatedAt;
}
```

---

# 7. Recurring Item Types

```dart
enum RecurringItemType {
  subscription,
  bill,
}
```

Examples:

## Subscription

```text
Netflix
Spotify
ChatGPT Plus
Adobe Creative Cloud
Google One
Gym Membership
```

## Bill

```text
Rent
Internet
Insurance
Electricity
Phone
School fees
Domain renewal
Hosting
```

Avoid overcomplicating the model in v1.

---

# 8. Status Model

Use:

```dart
enum ItemStatus {
  active,
  paused,
  cancelled,
}
```

Trial should not be a status.

A trial is an active recurring item with:

```text
isTrial = true
trialEndDate != null
```

This makes the model easier to reason about.

---

# 9. Billing Frequencies

Support the following in v1:

```dart
enum BillingFrequency {
  weekly,
  monthly,
  quarterly,
  semiAnnual,
  yearly,
  custom,
}
```

Custom recurrence may be represented as:

```text
Every N days
Every N weeks
Every N months
Every N years
```

But the initial UI should emphasize the common options.

Recommended quick options:

```text
Weekly
Monthly
Quarterly
Yearly
```

Custom can live under "More".

---

# 10. Recurrence Calculation

Centralize recurrence logic.

Do not scatter date calculations across screens.

Example:

```dart
DateTime calculateNextDueDate({
  required DateTime fromDate,
  required BillingFrequency frequency,
  int interval = 1,
});
```

Special care is required for monthly recurrence.

Example:

```text
31 January
```

should not break when advancing one month.

The application must define a consistent rule such as:

> If the target month has fewer days, use the last valid day of that month.

Example:

```text
31 Jan → 28 Feb
31 Mar → 30 Apr
```

or 29 February on leap years.

Write explicit tests for these cases.

---

# 11. Monthly Equivalent Calculation

The dashboard should normalize costs into monthly and annual equivalents.

Recommended logic:

```text
Weekly:
amount × 52 / 12

Monthly:
amount

Quarterly:
amount / 3

Semi-annual:
amount / 6

Yearly:
amount / 12
```

Annual equivalent:

```text
monthlyEquivalent × 12
```

Keep calculations deterministic and centralized.

Example:

```dart
double calculateMonthlyEquivalent(RecurringItem item);
double calculateAnnualEquivalent(RecurringItem item);
```

---

# 12. Multi-Currency Handling

Trackly v1 should allow users to enter different currencies.

Examples:

```text
USD
EUR
GBP
RWF
KES
NGN
ZAR
```

Do NOT automatically convert currencies in v1.

If the user has:

```text
Netflix       USD 15
Internet      RWF 30,000
Hosting       EUR 8
```

the dashboard should not invent a combined total unless exchange rates are available.

Recommended behavior:

## One currency only

Show:

```text
$84.37 / month
```

## Multiple currencies

Show grouped totals:

```text
Monthly recurring

USD 54.37
RWF 30,000
EUR 8.00
```

Future versions may support exchange rates.

Do not introduce a currency API into the v1 architecture.

---

# 13. Local Database

Use Drift over SQLite.

Recommended database:

```text
trackly.db
```

Initial database version:

```text
1
```

Core tables:

```text
recurring_items
payments
categories
```

Optional later:

```text
notification_logs
```

The service catalog is NOT a database table. It is a static Dart list (section 47).

---

# 14. recurring_items Table

Suggested schema:

```text
id TEXT PRIMARY KEY

name TEXT NOT NULL
type TEXT NOT NULL

amount REAL NOT NULL
currency_code TEXT NOT NULL

frequency TEXT NOT NULL
interval INTEGER NOT NULL DEFAULT 1

start_date DATETIME NOT NULL
next_due_date DATETIME NOT NULL

status TEXT NOT NULL

is_trial BOOLEAN NOT NULL DEFAULT FALSE
trial_end_date DATETIME NULL

reminders_enabled BOOLEAN NOT NULL DEFAULT TRUE
reminder_days_before INTEGER NOT NULL DEFAULT 3

category_id TEXT NULL
notes TEXT NULL

logo_key TEXT NULL

created_at DATETIME NOT NULL
updated_at DATETIME NOT NULL
```

`logo_key` is a nullable reference into the bundled service catalog (see section 47).
It is not a path or URL. It is null for custom services.

Optional later:

```text
website_url
cancel_url
color_value
```

Do not require those fields for v1.

---

# 15. payments Table

This table stores payment history.

Suggested schema:

```text
id TEXT PRIMARY KEY
recurring_item_id TEXT NOT NULL

amount REAL NOT NULL
currency_code TEXT NOT NULL

due_date DATETIME NOT NULL
paid_date DATETIME NULL

status TEXT NOT NULL

created_at DATETIME NOT NULL
```

Payment status:

```dart
enum PaymentStatus {
  upcoming,
  paid,
  skipped,
}
```

Avoid using "failed" in v1 because Trackly is not processing payments and therefore cannot know whether a real transaction failed.

---

# 16. categories Table

Suggested schema:

```text
id TEXT PRIMARY KEY
name TEXT NOT NULL
icon TEXT NULL
sort_order INTEGER NOT NULL
is_system BOOLEAN NOT NULL
```

Seed simple categories:

```text
Entertainment
Software
Utilities
Housing
Transport
Insurance
Health
Education
Fitness
Business
Other
```

Users may choose a category, but category selection should remain optional.

---

# 17. Settings Storage

Use `shared_preferences` for simple scalar settings.

Examples:

```text
default_currency
default_reminder_days
theme_mode
analytics_enabled
notification_permission_requested
first_launch_completed
```

Do not put all settings into SQLite unless necessary.

---

# 18. Home Screen

The home screen should remain the primary product experience.

Recommended structure:

```text
Header
↓
Curved Hero
↓
Status Summary
↓
Quick Add
↓
Upcoming Charges
↓
Recent Payments
↓
Bottom Navigation
```

---

# 19. Hero Section

Use the dark blue matte curved hero design.

The hero should show:

```text
Your recurring cost

$84.37 / month
$1,012.44 per year
```

For multiple currencies, show a summarized variant:

```text
Your recurring cost

USD 54.37
RWF 30,000
+ 1 other currency
```

The hero should not become overloaded.

Do not place charts inside it in v1.

---

# 20. Quick Add

Quick Add should allow a recurring item to be created directly from Home.

Minimum fields:

```text
Service name
Amount
Frequency
```

Optional inline:

```text
Currency
Start date
```

If omitted:

```text
Currency -> use default currency
Start date -> today
```

The user taps the labeled **Save** button (not a plus icon; the bottom-nav `+` opens the full add form).

Save is disabled until name, amount and frequency are valid. The subscription is then immediately created.

After save:

```text
Subscription added
Next charge: 8 Nov
Reminder: 3 days before
```

The user may then tap:

```text
Add details
```

to edit:

- category
- trial
- notes
- reminder
- billing date
- item type
- cancellation link later

This keeps onboarding extremely fast.

---

# 21. Add/Edit Subscription Screen

Fields:

```text
Name
Type
Amount
Currency
Billing frequency
Start date
Next due date
Category
Reminder
Trial
Notes
Status
```

Recommended flow:

```text
Basic
↓
Schedule
↓
Reminder
↓
Optional details
```

Avoid a long form with every field visible immediately.

---

# 22. Free Trial Support

Free trials are a first-class feature.

Model:

```text
isTrial = true
trialEndDate = 2026-11-15
```

The user should be able to enter:

```text
Service: Canva Pro
Trial ends: 15 Nov
Then: $14.99/month
```

The app should schedule a dedicated trial-ending reminder.

Example:

```text
Canva Pro trial ends in 3 days
You'll be charged $14.99/month afterwards.
```

When the trial date passes, the item should automatically behave as an active paid subscription.

Do not silently mark it cancelled.

---

# 23. Upcoming Charges

Upcoming should be sorted ascending by due date.

Home subset (decided):

```text
Next 5 charges, but only those due within the next 30 days
```

A "See all" link opens the full upcoming list.

Each row:

```text
Logo/Icon
Name
Frequency • Currency
Due status
Amount
Chevron
```

Examples:

```text
Netflix
Monthly • USD
Due tomorrow
$15.49
```

Use semantic labels:

```text
Due today
Due tomorrow
In 3 days
18 Oct
```

Avoid showing raw dates where a relative label is more useful.

---

# 24. Recent Payments

Show the most recent 3-5 recorded payments.

Example:

```text
YouTube Premium
Paid 2 Oct
$13.99
```

Tap opens payment history or item details.

---

# 25. Calendar Screen

Calendar is a secondary view of upcoming charges.

Recommended modes:

```text
Month calendar
Agenda list
```

Default to agenda/list if it proves more usable.

Each date can display:

```text
8 Oct
Netflix      $15.49
```

Calendar totals:

```text
Due this month: $84.37
```

Respect multi-currency grouping.

---

# 26. Insights Screen

Keep v1 Insights simple.

Recommended:

## Monthly equivalent

```text
$84.37/month
```

## Annual equivalent

```text
$1,012/year
```

## Category breakdown

```text
Entertainment  $26.48
Software       $23.99
Fitness        $35.00
```

## Active subscriptions

```text
6
```

## Upcoming in next 30 days

```text
5 payments
```

Avoid complicated financial analysis.

Trackly is not a budgeting app.

---

# 27. Payment Recording

Trackly does not automatically know whether a bank/card payment actually occurred.

Therefore payment recording in v1 should be explicit.

When due:

```text
Netflix
$15.49
Due today

[ Mark as paid ]
[ Skip ]
```

When marked paid:

1. Create payment history row.
2. Advance `next_due_date`.
3. Reschedule next reminder.
4. Log analytics event.
5. Update dashboard.

Optional convenience:

```text
Auto-record on due date
```

should NOT be enabled in v1 because the app cannot verify a payment occurred.

---

# 28. Advance Next Due Date

When payment is marked paid:

```text
current due date
→ recurrence engine
→ next due date
```

Do not calculate from "today" unless the user explicitly changes the schedule.

Example:

```text
Netflix due 15 Oct
Marked paid on 18 Oct
```

Next due should still normally be:

```text
15 Nov
```

not:

```text
18 Nov
```

This prevents schedule drift.

---

# 29. Reminder System

Use local notifications.

No backend required.

Recommended notifications:

```text
Subscription due soon
Trial ending soon
Payment due today
```

Default:

```text
3 days before
```

User-configurable options:

```text
Same day
1 day before
3 days before
7 days before
Custom
```

---

# 30. Notification Scheduling

Use timezone-aware scheduling.

Recommended packages:

```yaml
flutter_local_notifications:
timezone:
```

Conceptual workflow:

```text
Recurring item created
↓
Calculate reminder date
↓
Schedule local notification
↓
Store reminder configuration
```

Whenever these fields change:

```text
next_due_date
reminder_days_before
reminders_enabled
status
```

cancel the old notification and reschedule.

---

# 31. Notification IDs

Local notification IDs are typically integers.

Do not use database UUIDs directly as notification IDs.

Create a stable mapping such as:

```text
hash(recurringItemId + reminderType)
```

or maintain an integer notification ID field.

Recommended reminder types:

```text
due_soon
due_today
trial_ending
```

Ensure collisions are tested.

---

# 32. Notification Tap Handling

When the user taps a reminder:

```text
Notification
↓
Open Trackly
↓
Navigate to recurring item detail
```

Notification payload should contain only:

```text
item_id
notification_type
```

Do not put sensitive free-form data in the payload.

---

# 33. Notification Permissions

Android and iOS require notification permission handling.

The app should not ask immediately on first launch.

Better flow:

```text
User creates first subscription
↓
"Would you like Trackly to remind you before it renews?"
↓
Request notification permission
```

This is more contextual and should improve permission acceptance.

Track analytics:

```text
notification_permission_prompted
notification_permission_granted
notification_permission_denied
```

---

# 34. Firebase Analytics

Use Firebase Analytics for anonymous product analytics.

Do not send custom names such as:

```text
Netflix
Spotify
Gym near my house
```

Instead send metadata.

Example:

```dart
await analytics.logEvent(
  name: 'subscription_created',
  parameters: {
    'item_type': 'subscription',
    'frequency': 'monthly',
    'currency': 'USD',
    'has_reminder': true,
    'is_trial': false,
  },
);
```

---

# 35. Analytics Event Taxonomy

Define events before implementation.

Recommended:

```text
app_opened

subscription_created
subscription_updated
subscription_paused
subscription_resumed
subscription_cancelled
subscription_deleted

bill_created

trial_created
trial_ended

quick_add_started
quick_add_completed
quick_add_abandoned

reminder_enabled
reminder_disabled
reminder_scheduled
reminder_opened

payment_recorded
payment_skipped

home_opened
calendar_opened
insights_opened
history_opened

upcoming_item_opened
recent_payment_opened

notification_permission_prompted
notification_permission_granted
notification_permission_denied

currency_changed
theme_changed
```

---

# 36. Useful Analytics Parameters

Examples:

```text
item_type
frequency
currency
is_trial
has_reminder
reminder_days_before
entry_method
category
screen
```

For entry method:

```text
quick_add
full_form
```

Do not send:

```text
subscription_name
notes
raw user text
```

---

# 37. Core Product Funnel

Recommended activation funnel:

```text
first_open
    ↓
quick_add_started
    ↓
subscription_created
    ↓
reminder_enabled
    ↓
second_subscription_created
    ↓
notification_opened
    ↓
payment_recorded
```

Questions this lets us answer:

```text
What percentage add a subscription?
How many create 3+ subscriptions?
How many enable notifications?
How many return via a reminder?
Do trial users retain better?
Does Quick Add improve activation?
```

---

# 38. Sentry

Use Sentry for technical errors.

Capture:

- Drift/SQLite exceptions
- Notification scheduling failures
- Date recurrence calculation crashes
- Flutter framework errors
- Async errors
- Serialization errors
- App startup failures

Do not send expected business conditions as Sentry errors.

Example:

```text
Notification permission denied
```

is NOT a Sentry incident.

It is an analytics event.

---

# 39. Sentry Breadcrumbs

Useful breadcrumbs:

```text
screen=home
quick_add_opened
frequency=monthly
item_saved
notification_schedule_started
notification_schedule_success
```

For a technical failure:

```text
screen=edit_item
item_update_started
database_write_started
database_error
```

Never add raw notes or arbitrary service names unless explicitly required.

---

# 40. Firebase vs Sentry Responsibilities

```text
Firebase Analytics
------------------
Feature usage
Activation
Retention
Funnels
Reminder engagement
Screen usage
Subscription creation behaviour

Sentry
------
Crashes
Unhandled exceptions
Database failures
Notification failures
Performance problems
Release regressions
```

Do not add Firebase Crashlytics in v1 unless there is a specific reason.

Sentry already covers engineering error monitoring.

---

# 41. Privacy Model

Trackly should have a strong privacy story.

Recommended positioning:

> Your subscriptions and bills stay on your device.

Trackly should not require:

- Bank credentials
- Card numbers
- Financial account access
- User accounts
- Cloud storage

Firebase and Sentry should only receive anonymous/technical telemetry.

---

# 42. Database Migration Strategy

Drift database schema version must be explicit.

Example:

```dart
@override
int get schemaVersion => 1;
```

Future migrations:

```text
v1 → base subscriptions/payments/categories

v2 → cancellation metadata

v3 → multiple reminders

v4 → custom recurrence improvements
```

Never rely on deleting the database during production migrations.

Write migration tests.

---

# 43. State Management

Use Riverpod.

Recommended controllers/providers:

```text
homeSummaryProvider

recurringItemsProvider
upcomingItemsProvider
recentPaymentsProvider

subscriptionControllerProvider
paymentControllerProvider
reminderControllerProvider

insightsProvider
calendarProvider

settingsProvider
```

Avoid placing business rules inside widgets.

---

# 44. Home Summary Model

Recommended:

```dart
class HomeSummary {
  final Map<String, double> monthlyTotalsByCurrency;
  final Map<String, double> yearlyTotalsByCurrency;

  final int activeCount;
  final int trialCount;
  final int cancelledCount;

  final List<RecurringItem> upcoming;
  final List<Payment> recentPayments;
}
```

Home should derive this state from Drift queries.

---

# 45. Reactive Database Queries

Use Drift streams for screens that should update automatically.

Example:

```text
subscription added
↓
database changes
↓
home provider emits
↓
hero total updates
↓
upcoming list updates
```

Avoid manual refresh calls wherever reactive streams are sufficient.

---

# 46. Search

Home has a search icon.

Search across:

```text
Subscription name
Bill name
Category
```

Initial implementation can use simple local SQL filtering.

No external search engine.

---

# 47. Service Catalog

Do not make internet logo lookup a dependency for v1.

Decided approach:

Ship a small local service catalog for common subscriptions as a static Dart list
(for example `lib/features/subscriptions/domain/service_catalog.dart`).
It is not stored in the database, so it needs no migrations and is searched in memory.

The database stores only `logo_key` on each recurring item.
The row widget looks the key up in the catalog.
Quick Add's "Search a service" field searches the same list.

Example services:

```text
Netflix
Spotify
YouTube Premium
Google One
Apple Music
iCloud+
Microsoft 365
Adobe
ChatGPT Plus
Amazon Prime
Disney+
Dropbox
Canva
Notion
```

Each catalog entry contains:

```text
key            (stable, lowercase, for example 'amazon_prime')
display_name
local icon asset path
suggested category
```

Icon resolution order:

```text
1. logo_key found in catalog -> catalog asset
2. otherwise                 -> category icon
3. otherwise                 -> generic icon
```

Keys are permanent identifiers. Never rename a key once released.
If a key is removed from the catalog later, fall back to the category icon.

Users must always be able to enter any custom service.

---

# 48. Icons and Logos

For v1:

```text
Bundled local assets
Generic fallback icons
```

Storage:

```text
assets/logos/<key>.svg
```

- Declared in pubspec.yaml under `flutter: assets:`
- SVG preferred (needs the flutter_svg package)
- Displayed at 44-48 dp inside a rounded square (radius 12-14 dp)

Decided rollout (hybrid):

```text
Start with monogram tiles (initial letter on a neutral tile) for every catalog service.
Replace a monogram with an official logo only after confirming that brand's usage rules.
```

Swapping a monogram for a logo only means adding the asset file. No schema or code change.

Do not hotlink third-party logos from the internet.

Ensure trademark usage is appropriate.

If uncertain, use generic category icons and let the user choose an icon later.

---

# 49. Design System

Use Material 3 as the base but customize the visual language.

The design guide (trackly_design_guide.md) is the source of truth for visuals. Dark mode is the reference theme; light mode keeps the same hierarchy.

Dark role hierarchy:

```text
#07111C background -> App background and hero
#0D1B28 surface    -> Cards and transactional rows
#0D2730 teal tint  -> Quick Add panel
#122433 surface    -> Inputs
#16C7BE teal       -> Primary actions, active nav
Green              -> Active / paid
Amber              -> Trial / upcoming
Red                -> Cancelled / urgent due
```

Avoid purple.

---

# 50. Curves

Curves should communicate section hierarchy.

Use:

```text
Hero bottom edge
Quick Add panel boundary
Major header surfaces
```

Do not curve individual transaction/payment rows.

Design rule:

```text
Large curves      = major sections
Rounded rectangles = cards/actions
Pills             = status/reminders
```

---

# 51. Navigation

Recommended bottom navigation:

```text
Home
Insights
Add
Calendar
More
```

The centered Add action can be visually emphasized.

However, because Home already supports Quick Add:

```text
Home Quick Add -> fastest entry
Add button     -> full detailed form, shown in a panel sliding up from the nav bar
```

This gives both casual and advanced entry modes.

---

# 52. More Screen

Keep More simple:

```text
All subscriptions
Payment history
Categories
Settings
About
Privacy
```

Avoid adding unnecessary secondary features.

---

# 53. Settings

Recommended v1 settings:

```text
Default currency
Default reminder timing
Theme
Notifications
Analytics preference if exposed
Clear payment history
Export data
About
Privacy policy
```

Do not expose advanced technical settings.

---

# 54. Export

Export is useful for trust and portability.

Recommended v1 or v1.1:

```text
CSV export
```

Export:

```text
subscriptions.csv
payments.csv
```

Optional later:

```text
JSON full backup
```

No cloud account is necessary.

---

# 55. Import

Import can be deferred.

If added later:

```text
CSV
JSON backup
```

Validate imports carefully.

Never silently overwrite local data.

---

# 56. Backup Strategy

Because the app is local-only:

v1:

```text
Manual export
```

Future:

```text
Device backup
Encrypted local backup
Optional cloud sync
```

Do not build sync before there is user demand.

---

# 57. Testing Strategy

The most important tests are domain tests.

## Recurrence Tests

Examples:

```text
15 Oct monthly -> 15 Nov

31 Jan monthly -> last valid day of Feb

29 Feb yearly -> defined leap-year behavior

15 Oct quarterly -> 15 Jan

1 Jan yearly -> 1 Jan next year
```

## Monthly Equivalent Tests

```text
$12 monthly -> $12/month

$120 yearly -> $10/month

$30 quarterly -> $10/month

$10 weekly -> approximately $43.33/month
```

## Payment Tests

```text
Mark paid
→ payment inserted
→ next date advanced
→ reminder rescheduled
```

## Reminder Tests

```text
Due 10 Nov
3 days before
→ reminder scheduled for 7 Nov
```

## Trial Tests

```text
Trial ends 12 Nov
Reminder 3 days before
→ 9 Nov
```

Aim for high test coverage in:

```text
Recurrence engine
Cost normalization
Reminder calculations
Database migrations
```

UI coverage does not need to be as high.

---

# 58. Notification Testing

Test:

```text
Permission granted
Permission denied
Notification scheduled
Notification cancelled
Subscription updated
Subscription cancelled
App restarted
Timezone changes
DST changes
Device reboot where applicable
```

Use timezone-aware scheduling.

---

# 59. Timezone Handling

Store dates consistently.

Recommended:

```text
Store UTC timestamps for exact moments where appropriate
```

But recurring billing dates are often calendar-based.

The recurrence engine should preserve the user's local billing date semantics.

Example:

```text
Netflix renews on the 15th
```

should remain the 15th in the user's local timezone.

Be careful not to accidentally shift it because of UTC conversion.

---

# 60. No Banking Integration in v1

Do not add:

- Open Banking
- Card scraping
- Email receipt parsing
- SMS transaction parsing
- Bank APIs

These create:

- Privacy complexity
- Regulatory complexity
- Permission friction
- Backend requirements
- Higher testing scope

Manual entry is intentional for v1.

---

# 61. No Automatic Subscription Detection in v1

Do not attempt to detect subscriptions from:

```text
Bank transactions
Emails
SMS
Play Store billing
App Store billing
```

This can be researched later if user demand is strong.

---

# 62. No Payment Processing

Trackly tracks recurring payments.

It does not process them.

Never collect:

```text
Card number
CVV
Bank password
Mobile money PIN
```

External payment links may be considered later.

---

# 63. CI/CD

Recommended GitHub Actions pipeline.

For every pull request:

```text
flutter pub get
flutter analyze
flutter test
```

Optional:

```text
flutter build apk --debug
```

Release pipeline:

```text
Tag release
↓
Run tests
↓
Build AAB
↓
Upload source/debug symbols where needed
↓
Create Sentry release
↓
Internal Play testing
↓
Closed testing
↓
Production
```

---

# 64. Environments

Use:

```text
development
production
```

Optional:

```text
staging
```

Sentry:

```text
Debug -> development
Production -> production
```

Firebase Analytics:

Avoid polluting production data during development.

Use:

```text
Firebase DebugView
```

or disable analytics for ordinary debug builds.

---

# 65. Application Configuration

Recommended configuration:

```text
APP_NAME=Trackly

ANDROID_APPLICATION_ID=com.corecrest.trackly

IOS_BUNDLE_ID=com.corecrest.trackly

SENTRY_DSN=<value>
SENTRY_ENVIRONMENT=<development|production>

FIREBASE_ANALYTICS_ENABLED=true
```

Application IDs are examples and should be finalized before release.

---

# 66. Recommended Flutter Dependencies

Conceptual `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter

  flutter_riverpod:
  go_router:

  drift:
  drift_flutter:
  path_provider:

  shared_preferences:

  flutter_local_notifications:
  timezone:

  firebase_core:
  firebase_analytics:

  sentry_flutter:

  intl:
  uuid:

dev_dependencies:
  flutter_test:
    sdk: flutter

  flutter_lints:
  drift_dev:
  build_runner:
  mocktail:
```

Use current stable package versions when implementation starts.

Do not copy fixed dependency versions from old documentation.

---

# 67. Startup Sequence

Recommended application startup:

```text
Flutter binding initialized
↓
Database initialized
↓
Timezone data initialized
↓
Notification service initialized
↓
Firebase initialized
↓
Sentry initialized
↓
Reminder reconciliation
↓
runApp()
```

Reminder reconciliation should verify scheduled notifications against active items.

---

# 68. Reminder Reconciliation

Local notification schedules can become stale.

On application launch:

```text
Read active recurring items
↓
Compare expected reminders
↓
Cancel obsolete reminders
↓
Schedule missing reminders
```

Do not reschedule everything blindly if unnecessary.

Keep this operation lightweight.

---

# 69. Data Deletion

Users must be able to:

```text
Delete individual subscription
Clear payment history
Delete all local data
```

Before full reset:

```text
Confirm action
Cancel all scheduled notifications
Clear database
Clear relevant preferences
```

Do not clear analytics identifiers unless the platform APIs/policy support and require it.

---

# 70. Subscription Deletion vs Cancellation

These are different.

## Cancelled

Keep the item and history.

```text
Status = cancelled
No future reminders
No future due dates
History retained
```

## Deleted

Remove the item from the app.

Ask for confirmation.

Default user action should usually be:

```text
Cancel subscription
```

rather than deleting history.

---

# 71. Pausing

Paused items:

```text
No reminder notifications
Excluded from current recurring totals
Excluded from Upcoming
Counted in the Active status card, with a "Paused" pill on their rows
History retained
```

When resumed:

Ask whether to:

```text
Keep original schedule
```

or:

```text
Set a new next due date
```

The simple v1 behavior can default to requesting a new next due date.

---

# 72. Upcoming Logic

Recommended windows:

Home:

```text
Up to 5 charges, within the next 30 days
```

Calendar:

```text
Selected month
```

"Due soon" status:

```text
<= default reminder window
```

Examples:

```text
Due today
Due tomorrow
In 2 days
In 7 days
```

---

# 73. Insights Calculations

Only include:

```text
active recurring items
```

Exclude:

```text
cancelled
paused
```

For trials:

Decided: trials are excluded from the hero and Insights monthly/annual totals until the trial ends.

Trial rows show the future price clearly instead:

```text
Canva Pro
Trial
$14.99/month after 12 Nov
```

Once `trialEndDate` passes, the item counts toward totals as a normal active item.

A "Future recurring cost after trials" figure in Insights is a possible v1.1 addition.

---

# 74. Accessibility

Trackly should support:

- Dynamic text sizing
- Screen readers
- Minimum touch target sizes
- Sufficient contrast
- Semantic labels
- Clear status text beyond color

Do not rely on:

```text
Red = overdue
Green = paid
```

alone.

Also show:

```text
Due tomorrow
Paid
Cancelled
```

---

# 75. Localization

Build localization readiness from day one.

Use Flutter localization resources.

Avoid hardcoded strings inside widgets.

Initial:

```text
English
```

Potential follow-up languages:

```text
Spanish
French
Portuguese
German
Hindi
Indonesian
```

Analytics may guide localization priorities.

---

# 76. Date and Currency Formatting

Use locale-aware formatting.

Examples:

```text
$15.49
15,49 €
RWF 30,000
```

Dates:

```text
18 Oct 2026
Oct 18, 2026
```

depending on locale.

Do not hardcode American date formats globally.

---

# 77. MVP Scope

## Build in v1

- Home
- Curved dark-blue matte hero
- Quick Add
- Full Add/Edit form
- Subscriptions
- Recurring bills
- Free trials
- Local notifications
- Reminder timing
- Upcoming charges
- Payment recording
- Payment history
- Calendar/agenda
- Basic insights
- Multi-currency entry
- Categories
- Pause/cancel/delete
- Local database
- Firebase Analytics
- Sentry
- Dark/light theme readiness
- Localization-ready strings

---

# 78. Explicitly Excluded From v1

Do NOT build:

- Accounts
- Login
- Backend
- Cloud sync
- Firestore
- Bank connection
- Card connection
- SMS parsing
- Email parsing
- Automatic subscription detection
- AI
- OCR
- Receipt scanning
- Payment processing
- Live currency conversion
- Shared family accounts
- Widgets
- Wear OS
- Web application
- Desktop application
- Ads
- Paid plans

These can be considered only after actual usage data exists.

---

# 79. Suggested Implementation Order

## Phase 1 - Foundation

```text
Flutter project
Theme
Riverpod
GoRouter
Drift
Firebase Analytics
Sentry
```

## Phase 2 - Domain

```text
RecurringItem model
Recurrence engine
Monthly/annual normalization
Payment model
Unit tests
```

## Phase 3 - Database

```text
recurring_items
payments
categories
DAOs
migrations
```

## Phase 4 - Core UI

```text
Home
Hero
Status summary
Upcoming list
Quick Add
```

## Phase 5 - Full Management

```text
Add/Edit
Pause
Cancel
Delete
Payment recording
History
```

## Phase 6 - Notifications

```text
Permissions
Reminder scheduler
Trial reminders
Notification tap navigation
Reconciliation
```

## Phase 7 - Secondary Screens

```text
Calendar
Insights
More
Settings
```

## Phase 8 - Analytics

Verify:

```text
Activation funnel
Reminder engagement
Quick Add usage
Retention
```

## Phase 9 - Release

```text
Privacy policy
Play Data Safety
Store listing
Screenshots
Internal testing
Closed testing
Production
```

---

# 80. Definition of Done for v1

Trackly v1 is complete when a fresh user can:

```text
Install Trackly
↓
Open without creating an account
↓
Quick-add Netflix
↓
Set $15.49 monthly
↓
Automatically receive a next due date
↓
Enable reminder
↓
See Netflix in Upcoming
↓
Receive notification before due date
↓
Open notification into Netflix detail
↓
Mark payment as paid
↓
See payment in history
↓
See next due date advance one month
↓
See hero monthly total update correctly
```

All of this must work offline.

---

# 81. Recommended Analytics Success Metrics

Track:

## Activation

```text
% of first opens that create first recurring item
```

## Setup Depth

```text
Average subscriptions per activated user
```

## Reminder Adoption

```text
% with reminders enabled
```

## Notification Engagement

```text
Reminder open rate
```

## Retention

```text
Day 1
Day 7
Day 30
```

## Core Engagement

```text
Payments recorded per active user
Calendar opens
Insights opens
```

## Quick Add Performance

```text
Quick Add started
Quick Add completed
Quick Add abandoned
```

---

# 82. Recommended Product Quality Metrics

Monitor:

```text
Crash-free users
Crash-free sessions
Notification scheduling failure rate
Database error rate
Subscription creation failure rate
```

Sentry is the source for engineering quality.

Firebase Analytics is the source for product usage.

---

# 83. Future Roadmap Based on Evidence

Only after usage data supports it, evaluate:

## v1.1

```text
Widgets
CSV export
More reminder options
Better service catalog
Additional localizations
```

## v1.2

```text
Cancellation links
Subscription notes improvements
Custom recurrence
More insights
```

## v2

Potential:

```text
Encrypted backup
Optional cloud sync
Family/shared tracking
Currency exchange rates
Email/SMS-assisted detection
```

Do not commit to these before learning from real users.

---

# 84. Final Technical Architecture

```text
┌───────────────────────────────────────┐
│                TRACKLY                │
├───────────────────────────────────────┤
│                                       │
│ Flutter + Material 3                  │
│ Riverpod                              │
│ GoRouter                              │
│                                       │
├───────────────────────────────────────┤
│                                       │
│ Recurrence Engine                     │
│ Cost Normalization                    │
│ Payment Lifecycle                     │
│ Trial Logic                           │
│                                       │
├───────────────────────────────────────┤
│                                       │
│ Drift / SQLite                        │
│                                       │
│ Recurring Items                       │
│ Payments                              │
│ Categories                            │
│                                       │
├───────────────────────────────────────┤
│                                       │
│ Local Notifications                   │
│                                       │
│ Renewals                              │
│ Bills                                 │
│ Trials                                │
│                                       │
├──────────────────┬────────────────────┤
│                  │                    │
│ Firebase         │ Sentry             │
│ Analytics        │                    │
│                  │ Errors             │
│ Usage            │ Crashes            │
│ Retention        │ Performance        │
│ Funnels          │ Diagnostics        │
│                  │                    │
└──────────────────┴────────────────────┘

NO BACKEND
NO LOGIN
NO BANK CONNECTION
LOCAL-FIRST
OFFLINE-CAPABLE
```

---

# 85. Core Implementation Rule

Trackly should remain intentionally small.

If a feature does not improve one of these core jobs:

```text
Know what I pay regularly
Know what is charging next
Get reminded before it happens
Record that I paid it
Understand my recurring cost
```

it should probably not be in v1.

The purpose of the first public release is not to build a complete personal finance platform.

The purpose is to ship a polished, useful recurring-payment tracker, gather real-world analytics, and learn from actual user behavior.

---

# 86. Phase 5 decisions (as built)

## Payments

- **Mark as paid** records a payment for the current due date (paid date = today) and moves the next due date one period on, **from the due date, not from today**. Paying 15 Oct on 18 Oct still gives 15 Nov.
- The billing anchor is the start date's day, so a clamped month recovers (28 Feb, then 31 Mar).
- **Skip this charge** records a skipped payment (no paid date) and moves on the same way. Skipped charges are not "recent payments".
- Both write in one database transaction and show a snackbar with **Undo**, which removes the payment and restores the previous due date.
- A newer message replaces the one showing; messages never queue behind an Undo.

## Lifecycle

- **Pause**: no confirmation (reversible). Paused items leave Upcoming, totals and reminders; they still count in the Active card and show a Paused chip.
- **Resume**: asks for the next charge date. The default is the next real occurrence on or after today, along the item's own schedule.
- **Cancel**: asks first. The item and its history stay; no more due dates or reminders.
- **Delete**: asks first. Removes the item and its payment history. This cannot be undone.

## Editing

- Edit reuses the add panel, filled in, sliding up from the bottom of the item's own screen.
- The date slot is "Next charge" when editing.
- Moving the next charge to a different day of the month also moves the billing anchor.
- A free trial's first charge is its end date.
- Interval, status and creation time are not editable here.

## Screens and navigation

- Item detail: `/item/:id`, All subscriptions: `/subscriptions?filter=active|trial|cancelled`, Payment history: `/history`. All sit outside the tab shell.
- Home status cards open the matching filter; "See all" opens All subscriptions / Payment history; rows open the item.
- More lists All subscriptions and Payment history.

## Analytics

`payment_recorded`, `payment_skipped`, `subscription_paused`, `subscription_resumed`, `subscription_cancelled`, `subscription_deleted`, `subscription_updated`. Parameters are metadata only: item type, frequency, currency, trial flag. Never names or notes.

# 87. Light theme (as built)

- Light is the default theme mode for now; the settings screen will let users choose and persist light, dark or system.
- Per-theme values live in `TracklyTokens` (a theme extension); widgets read tokens instead of hard-coding colors.
- Fonts are bundled as variable fonts: Playfair Display for the wordmark and page titles, Inter for everything else. Weight is set through the `wght` axis.
- Contrast is tested: body text, placeholders, every chip tone and the active nav label meet 4.5:1; icons and graphics meet 3:1.

# 88. Service logos (as built)

- Logos are **bundled SVG files** in `assets/logos/<key>.svg`. They are not stored in the database. The database stores only `logo_key` on each item; the catalog (`service_catalog.dart`) maps a key to its file.
- Source: the open CC0 collections **gilbarbara/logos** and **Simple Icons** (svgrepo.com blocks automated downloads). Single-colour Simple Icons marks get their official brand colour. Every file, its source and the trademark notice are in `assets/logos/LICENSES.md`. CC0 covers the files, not the brands.
- 12 services have logos: Netflix, YouTube Premium, Spotify, Apple Music, Apple TV+, Max, Paramount+, Microsoft 365, Google One, iCloud+, ChatGPT Plus, Adobe. Amazon Prime, Disney+ and Hulu are not in either collection and show a letter tile.
- Logos sit on a white tile in every theme (several marks are black).
- New items whose name exactly matches a catalog service (any case) get its `logo_key` and category automatically; existing items are backfilled the same way at app start. A key already set is never overwritten.
- Adding a logo later is a file plus one `logoAsset:` line, with no schema change. Tests check that every file exists, is named by its key, is safe, and really draws.

# 89. Calendar and Insights (as built)

## Calendar

- A **month grid** (week starts on the locale's first day), with month navigation (buttons or a horizontal swipe) and a **Today** button when another month is showing.
- Each day shows one small dot per kind of charge on it: overdue (red), due (amber), paid (green), skipped (grey). Dots are decoration only; the list under the grid and each day's screen-reader label give the same facts in words.
- Opening the current month selects today; any other month selects its first day.
- Two figures per currency, never merged:
  - **Total this month**: every counted charge in the month, paid or not, so the number does not shrink as the user pays.
  - **Left from {selected day}**: charges still to pay (due or overdue, not paid or skipped) from the selected day to the end of the month. Choosing the 1st of a month gives the whole month.
- Charges are **projected** from each active item's schedule starting at its next due date (`occurrencesInRange`), so a weekly item appears every week and a monthly one in any month ahead. Recorded payments and skips show on the date they were due, at the amount paid.
- Charges before today that are not recorded are **overdue** and stay on their original date.
- Paused and cancelled items have no scheduled charges; their recorded history stays visible.
- A **skipped** charge is shown but never counted. A charge made while a free trial runs (up to and including its end date) is shown with a Trial chip and is not counted, as on Home and Insights.

## Insights

- Per-month and per-year cost per currency (the same figures as the Home hero).
- Counts: **Active** (active and not in a trial; paused items are *not* counted here, unlike the Home Active card), **Trial**, and **Charges ahead**.
- **Charges ahead** counts every charge from today to one calendar month ahead (the Home Upcoming window, inclusive at both ends), uncapped. It includes a weekly item's repeats, a trial's first charge and one overdue charge per item, so a monthly item due today counts twice (today and exactly one month ahead).
- **By category**: the monthly cost per category, largest first, with its share, one block per currency. Items without a category are grouped as Other. Only active, non-trial items are included.
- No charts beyond a thin share bar (design guide §40).

## Analytics

`insights_opened` and `calendar_opened` are logged when the tab is chosen (the tab screens stay alive once visited, so building them is not "opening").

## Testing

Pure logic (`occurrencesInRange`, `buildCalendarMonth`, `buildInsightsSummary`) has unit tests including month-end clamping, leap years, weekly and custom schedules, trials, paused items and multiple currencies. Screen tests cover the summary figures, day selection, month stepping, overflow on a 320 dp screen with 1.6x text, and the analytics events.

# 90. Launch splash (as built)

- The app shows a **splash** while it starts: the logo large and centred, the name "Trackly" in the serif title face, the tagline and a small three-dot loader. `BootGate` (in `lib/core/startup/`) puts it on screen immediately and swaps in the app when start-up (analytics, notifications, preferences) finishes.
- It stays for **at least one second** (`BootGate.defaultMinimumDisplay`) so a fast start does not flash the logo and vanish, and for as long as start-up takes if that is longer. It cross-fades into the app.
- If start-up fails, the splash shows "Couldn't start Trackly" with **Try again** instead of spinning forever; the error is reported through the error reporter.
- The logo is `assets/illustrations/trackly_logo.svg`, traced from the Android launcher artwork (a navy T with a folded gold ribbon) as three gradient-filled shapes, so it scales to any size and works on any background. The tagline, **"Know what's charging next."**, is `appTagline` in `app_en.arb`.
- With the system "remove animations" setting on, the logo and text appear at once and the loader is still.
- The splash uses the light theme, like the rest of the app until theme choice exists (§87). The very first frame, before Flutter starts, is still the native launch screen (plain white).
- **Not done:** the iOS app icon is still Flutter's default; only the Android icon was redesigned.

# 91. Reminder time of day (as built)

- Each item has its own **reminder time**, set in the add/edit form under the day chips ("Remind me at", with the phone's 12- or 24-hour style) and shown on the item screen ("3 days before at 6:30 PM"). Before this, every reminder was fixed at 9:00.
- It is stored as `reminder_minute_of_day` on `recurring_items`: minutes after local midnight, 0-1439 (a `CHECK` enforces the range). **Schema version 2**; the upgrade adds the column, and existing items get 540 (09:00), exactly what they had, so nothing changes until the user edits an item. The v2 schema and its test helpers are committed under `drift_schemas/` and `test/database/generated/`, with an upgrade test that starts from a v1 database containing data.
- *(Superseded by §99 for the "due today" reminder, which is now always at 09:00 unless the person chose "same day".)* The planner puts both reminders (the "N days before" one and the "due today" one) at the item's time. A time that has already passed today is left out, as before. Changing the time reschedules the same notifications (their ids do not depend on the time) rather than adding duplicates.
- New items, including Quick Add, start at the default time from Settings (§92), 09:00 until the user changes it.
- Analytics: `subscription_created` gains `reminder_hour` (0-23), nothing finer.

# 92. Settings (as built)

Opened from the Home gear and from **More > Settings** (`/settings`, a sub-page with a back button). Four sections:

| Section | What it does |
| --- | --- |
| **For new subscriptions** | Default **currency**, and default **reminder** timing (Same day / 1 / 3 / 7 days before, and the time of day). Used by Quick Add and by the add form for a new item. Existing items are never changed. The default currency is also the one empty totals show on Home, Calendar and Insights. |
| **Appearance** | **System / Light / Dark**. Light until the user chooses (§87). Applies at once. |
| **Notifications** | Shows whether the phone lets Trackly notify. **Turn on** asks for the permission (and schedules the reminders if granted). If the user refuses, the screen says to allow it in the phone's settings; Android will not ask again. The status refreshes when the user returns from the phone's settings. States that a reminder can arrive a few minutes late (Android delays inexact alarms). |
| **Your data** | **Export data (CSV)** (see §94), **Clear payment history** (payments and skips; subscriptions and their next dates stay) and **Delete all data** (every item, its history, every scheduled reminder and every setting). Both ask for confirmation, with the consequence in the text, and cannot be undone. |

## Storage

- Choices are kept in `shared_preferences` behind `SettingsStore` (keys `default_currency`, `theme_mode`, `default_reminder_days`, `default_reminder_minute`). A missing or unusable value reads as "not chosen" and the default applies. A write that fails is reported through the error reporter and does not break the screen: the choice is already applied in memory.
- Settings are not in the database, so they are not part of the CSV export.
- **Delete all data** removes items and payments in one transaction, clears the settings, then cancels all notifications. If cancelling fails the data is still gone, the failure is reported, and the next launch reconciles reminders anyway.
- It does not delete data held outside the phone (there is none in v1: the app is local-first with no account) or Android's own record of the permission.

## Analytics

`currency_changed` (`currency`), `theme_changed` (`theme`), and the existing `notification_permission_*` events when **Turn on** is used. Nothing is logged for the data actions.

## Not done

Language choice (English only), a "Reminders off" master switch (turn them off per item), and a lock screen. Planned: Categories under More.

# 93. Search (as built)

- The search icon on Home opens a **search screen** (`/search`, a sub-page with a back button). The field is focused on open. Search runs on the phone as you type; there is no server and nothing is stored.
- It looks at every item, whatever its status: active, trial, paused and cancelled (cancelled ones show their Cancelled chip).
- **What matches:** the name, the category name and the notes. Every word of the query must appear somewhere in those (any order), so "family spotify" finds Spotify with the note "Family plan". Case and common Latin accents are ignored ("cafe" finds "Café").
- **Order:** names that start with the query, then names that contain it, then matches only in the category or notes. Inside each group, live items come before paused and cancelled ones, soonest due first, then by name.
- **States:** nothing added yet ("Nothing to search yet"), an empty query (a prompt), no matches (`No matches for "<query>"`), and results with a count ("3 results", announced to screen readers). Clear empties the field. Tapping a result opens the item; Back returns to the same search.
- The query is plain text, not a pattern, so characters like `+` or `(` search literally.
- Analytics: `search_opened` and `search_result_opened`, with no parameters. The query text is never logged (see the analytics rule on user text).
- **Not done:** matching on amount or currency, search history, filters inside search, and fuzzy matching of typos.

# 94. CSV export (as built)

**Settings > Your data > Export data (CSV)** opens the Android share sheet with two files, so the user can save them to Drive, email them to themselves or open them in Excel or Sheets. It is the user's way to take their data out of a phone-only app and to keep a backup they can read.

| File | Contents |
| --- | --- |
| `trackly-subscriptions-YYYY-MM-DD.csv` | One row per subscription, bill or trial: `name, type, status, amount, currency, frequency, every, start_date, next_due_date, free_trial, trial_end_date, reminders, reminder_days_before, reminder_time, category, notes, added_on, id`. Soonest due first. |
| `trackly-payments-YYYY-MM-DD.csv` | One row per recorded payment or skip: `subscription, due_date, paid_date, status, amount, currency, subscription_id, id`. Oldest first, named by subscription. `subscription_id` is what ties a payment to its subscription on import; the name alone is ambiguous when two subscriptions share one. |

## Format

- UTF-8 with a byte order mark (so Excel shows accents and non-Latin names correctly), comma separated, CRLF line ends, fields quoted per RFC 4180 when they hold a comma, quote or line break.
- Dates are `YYYY-MM-DD` and the reminder time is `HH:MM` (24 hour), so they sort and parse the same in every language. Amounts are plain numbers with a point and two decimals (`15.50`); the currency is a separate column and nothing is converted.
- `frequency` is `weekly`, `monthly`, `quarterly`, `semi_annual`, `yearly` or `custom_days`; `every` is the repeat count (for `custom_days`, the number of days). `status` is `active`, `paused` or `cancelled`; a trial is an active item with `free_trial = yes` and a `trial_end_date`.
- The column names are a contract: a change to them is a format change, so add columns at the end and say so here. The `id`, `subscription_id` and payment `id` columns were added (at the end) for import (section 97); the first CSV export (`preview.7`) did not have them.

## Safety

- **Spreadsheet formulas:** text the user typed (name, category, notes) that starts with `=`, `+`, `-`, `@`, a tab or a carriage return would run as a formula when the file is opened, so it is written with a leading apostrophe, which spreadsheets show as plain text. Numbers and dates are never altered.
- The export contains the user's complete financial list in plain text. Trackly builds the files in memory and hands them to the share sheet (`share_plus`); it writes no file of its own, and share_plus keeps the temporary copy the receiving app needs in the app's private cache. Android clears that cache when space is needed, and "Clear data" or uninstall removes it. Anything the user sends the file to is theirs to protect.
- Nothing is sent by the app itself: the user picks where the file goes.

## Behavior

- With nothing added yet it says so ("Nothing to export yet") and does not open the share sheet. If the share sheet cannot open it says "Couldn't export your data".
- Exporting changes no data and needs no confirmation.
- Analytics: `data_exported`, with no parameters (no counts or text).

## Not done

Exporting a single subscription, choosing columns or a date range, an Excel (`.xlsx`) file, and a scheduled automatic backup.

# 95. Privacy policy, About and data hygiene (as built)

## In the app

- **More > Privacy policy** and **More > About > Privacy policy** open Trackly's own policy page in the browser (`AppLinks.privacyPolicy` in `lib/core/config/app_links.dart`: `https://corecrest.tech/trackly/privacy-policy`). It is separate from the CoreCrest website's policy, because it must describe what the app collects (usage metrics and crash reports). If no app can open it, a message shows the address.
- **About** shows the logo, name, tagline, the installed version and build (`1.0.0 (8)`, read with `package_info_plus`), "Made by CoreCrest", and rows for the privacy policy, **Contact support** (a mail draft to `info@corecrest.tech`, subject "Trackly support") and **Open source licenses** (Flutter's license page).
- Links go through `LinkOpener` (`url_launcher`, external application), a seam that tests replace. The manifest declares the `https` and `mailto` intents under `<queries>` so they resolve on Android 11+.
- **The policy address is permanent once published**: it is built into every installed app and given to Google Play. Change it in one place, and keep the old page alive.

## The policy and Play forms

- The policy text is in `docs/privacy/trackly-privacy-policy.md` with a ready-to-upload `.html` copy. Retention is stated as 14 months (Firebase) and 90 days (Sentry), confirmed by the owner; if the project settings change, change the policy with them. The date is the date of writing. `tool/build_policy_html.py` rebuilds the HTML copy from the Markdown.
- `docs/play_data_safety.md` lists the facts the answers rest on and suggested Data safety answers. They are suggestions to verify against Google's current forms.
- The policy must stay true to the code. When analytics events, Sentry settings, permissions or the export change, review the policy in the same change.

## Data hygiene that the policy relies on

- **No advertising ID.** Firebase Analytics adds the advertising ID permissions on its own. The manifest removes `AD_ID`, `ACCESS_ADSERVICES_AD_ID`, `ACCESS_ADSERVICES_ATTRIBUTION` and `ACCESS_ADSERVICES_TOPICS` (`tools:node="remove"`) and turns off ad ID collection and ad personalization for Analytics. CI and the release workflow run `tool/apk_lacks_permission.sh`, which fails if the built APK requests any of them.
- **No user text in error reports.** A failed SQLite statement quotes its parameters (what the user typed). `scrubSentryEvent` (`lib/core/error/error_scrubber.dart`, set as Sentry's `beforeSend`) replaces everything from `, parameters:` onward in every exception and message, and drops message parameters. The statement itself stays because it only holds placeholders. A test runs a real `SqliteException` through it.
- Sentry runs with `sendDefaultPii = false`. Analytics events carry only item type, billing frequency, currency code, a trial flag, theme and counts (§80 rule: never names, notes or amounts).

## Not done

- **Categories** management (view, add, rename) under More.

# 96. Privacy choice (as built)

Usage statistics (Firebase Analytics) and error reports (Sentry) are **opt-in**: nothing is collected or sent until the person says yes.

## First launch

- Before the app is shown, a **"Help improve Trackly"** screen explains what Trackly never sends (subscriptions, payments, notes stay on the phone), what it can send if allowed (usage statistics; error reports), and links to the privacy policy. Two equal buttons: **Share anonymous data** and **Don't share** (same size and style; saying no costs one tap and the app works the same).
- The screen is a gate in `TracklyApp`'s builder, shown until both choices are recorded. Someone who updates from a build without this screen is asked on their first launch of the new version. It is never shown again once answered.

## Settings > Privacy

Two switches, **Usage statistics** and **Error reports**, changeable at any time. A change in Settings settles the other answer as "no" if it was never given, so the first-run screen cannot return.

## What each choice does

| | Off (or not yet asked) | On |
| --- | --- | --- |
| **Usage statistics** | The manifest sets `firebase_analytics_collection_enabled=false`, so Firebase collects nothing at launch. `FirebaseAnalyticsService` also drops events in Dart. Switching off after being on calls `resetAnalyticsData()`, which forgets the installation identifier. | `setAnalyticsCollectionEnabled(true)` at once. |
| **Error reports** | Sentry is **not started** (`io.sentry.auto-init=false` in the manifest; no `SentryFlutter.init` at launch), so not even its native crash handler runs. Turning it off in a session calls `Sentry.close()`. | Started at launch if previously allowed, or at once when switched on (`SentryErrorReporter.setEnabled`). |

The choices are stored in `shared_preferences` (`privacy_usage_stats`, `privacy_error_reports`; null means not asked). **Delete all data does not clear them**: someone who said no must not become "undecided" and be asked again, or have analytics resume.

## Rules

- A new service that sends anything off the phone needs its own choice (or an existing one) and must be off until it is given. The policy and `docs/play_data_safety.md` change in the same commit.
- The first-run screen's text, the Settings text, the policy and the Play answers must say the same thing.

## Not done

- A "reset my choice" action (the switches cover changing it), and region-specific behavior: the same opt-in applies everywhere.
- Consent for the optional CSV export is not needed: the person shares the files themselves.

# 97. CSV import (as built)

**Settings > Your data > Import data (CSV)** picks one or more files with the system file chooser (no storage permission needed; Trackly sees only the files chosen), shows what they would add, and adds it only after the person confirms. It reads Trackly's own export (restore) and any spreadsheet saved with the same columns.

## What it never does

- **Never changes or replaces anything already in Trackly.** A row that Trackly already has is left out and counted, so importing the same file twice changes nothing.
- **Never sends the file anywhere.** It is read and parsed on the phone.
- **Never writes anything before the person says Import.** The review is built from a plan; nothing is written until confirmed.
- **All or nothing for what it does write:** items and payments go in one database transaction.

## Files and columns

Two kinds of file are told apart by their header row (column names are not case sensitive; extra and missing optional columns are fine):

| File | Required columns | Optional columns |
| --- | --- | --- |
| Subscriptions | `name, amount, currency, frequency, next_due_date` | `type, status, every, start_date, free_trial, trial_end_date, reminders, reminder_days_before, reminder_time, category, notes, added_on, id` |
| Payments | `due_date, status, amount` and `subscription_id` **or** `subscription` | `paid_date, currency, id` |

Defaults for missing optional values: type `subscription`, status `active`, every `1`, start date = next due date, free trial `no`, reminders `yes`, 3 days before, 09:00, no category, no notes, added today.

## Rules for values

| Value | Accepted |
| --- | --- |
| Dates | `YYYY-MM-DD` that really exist (no `2026-02-30`), year 1900-2200 |
| Amounts | digits with a decimal point (`15.49`), 0 to 1,000,000,000. A comma is a decimal separator **only** in a semicolon-separated file (`15,49`); signs, symbols, thousands separators and exponents are refused |
| Currency | three letters, upper-cased |
| `frequency` | `weekly, monthly, quarterly, semi_annual, yearly, custom_days` (also `semi-annual`, `semiannual`, `annual`, `custom`); `every` is 1-3650 |
| `type` / `status` | `subscription, bill` / `active, paused, cancelled` (payments: `paid, skipped, upcoming`) |
| yes/no | `yes, no, true, false, 1, 0, y, n` |
| `reminder_time` | `HH:MM`; `reminder_days_before` 0-30 |
| `id`, `subscription_id` | letters, digits, `-` and `_`, up to 64 characters; generated when absent |
| Text | name up to 120 characters, notes up to 2,000 |
| Category | matched by name, ignoring case; unknown is left empty and noted (the row still imports) |

## Matching and duplicates

- **Subscriptions with an `id`** that Trackly has: left out. The same `id` twice in one import: the second is a problem.
- **Subscriptions without an `id`:** the same name (ignoring case and spaces), amount, currency, frequency, `every` and next due date as one Trackly has, or one earlier in the import: left out.
- **Payments** attach by `subscription_id` when the row has one, else by name; a name shared by two subscriptions is **refused as ambiguous, never guessed** (add `subscription_id`). They can attach to subscriptions already in Trackly or in the files imported together, in either file order. A payment is left out when its `id` exists or an identical one (same subscription, due date, status, amount, currency) does.

## Reading the files

- UTF-8 (with or without a byte order mark) and UTF-16 with a byte order mark. Anything else (a Windows-1252 "CSV" from Excel with accents) is **refused with advice to save as "CSV UTF-8"**, because guessing garbles names.
- Comma, semicolon or tab separated (the one the header line uses most). RFC 4180 quoting, line breaks inside quotes, CRLF/LF/CR.
- Limits: 5 MB per file and 50,000 rows. A quote that never closes or a stray quote refuses the file and names the line.
- The spreadsheet-formula guard written by the export (a leading apostrophe) is removed exactly: `csvTextRestore(csvText(x)) == x` for every text, tested.

## The review

A bottom sheet lists: new subscriptions and bills, new payments, rows already in Trackly, rows with problems (each with `file, line N` and a sentence in the person's language, first six then "...and N more"), files that cannot be read, and notes (rows imported with something adjusted). **Import** (or **Import, skipping the problem rows**) and **Cancel**; when nothing can be imported only **Close**.

After importing: reminders are scheduled by the usual reconciliation (they watch the items), catalog logos are matched by name, and analytics logs `data_imported` with no parameters.

## Not done

- Importing from another app's export, column mapping, and guessing formats: files must use the columns above.
- Updating existing subscriptions from a file (import only adds).
- Importing settings (they are not in the CSV files) and JSON backup.


---

# 98. Analytics completion (as built)

All event names in `AnalyticsEvents` are now sent. Before this, eight were defined but never logged, so the funnels and the reminder and Quick Add analysis in Phase 8 could not be answered. Events are still sent only after the person agreed (§96) and carry structured facts only: never a name, a note or typed text.

| Event | Sent when | Parameters |
| --- | --- | --- |
| `home_opened` | The app opens on Home, and each time the Home tab is chosen | none |
| `history_opened` | Payment history opens | none |
| `upcoming_item_opened` | A row in Home's Upcoming list is tapped | `item_type`, `frequency`, `currency`, `is_trial` |
| `recent_payment_opened` | A row in Home's Recent payments is tapped | same |
| `reminder_enabled` / `reminder_disabled` | An edit switches an item's reminders on or off (not when they stay as they were) | same |
| `quick_add_abandoned` | The Quick Add form was started and never saved, when the app goes to the background or the form is closed; once per attempt | none |
| `trial_ended` | The first time the app sees a trial's end date is before today | same |

Notes:

- The shared parameter set is `itemAnalyticsParameters` (`subscriptions/application/item_analytics.dart`), also used by the pause, resume, cancel, delete and update events.
- `SubscriptionActions.update` takes the original item as `previous` to tell a reminder switch from other edits.
- Tabs stay alive once visited, so Quick Add is not disposed when the person moves to another tab. "Abandoned" therefore counts leaving the app with a started form, plus the form being closed. A form that is abandoned and then continued keeps its single `quick_add_started`.
- A trial ends while the app is closed, so `TrialEndReporter` (`core/analytics/trial_end_reporter.dart`) checks at launch, on return to the app and when items change. The ids already counted are kept on the device (`reported_trial_ends`, not cleared by Settings reset) and forgotten when the trial is deleted or its end date moves later, so each ending is counted once. Trials that ended before this version are counted once on the first launch after the update.
- If the person has not agreed to usage statistics, these calls do nothing, but a trial end is still marked as counted so it is not sent if they agree later.

---

# 99. Reminder on the day itself (as built)

Every active item with reminders on gets a reminder on the day it is due, at **09:00**, in addition to the one the person chose.

| The person chose | They get |
| --- | --- |
| N days before (1, 3 or 7) at time T | N days before at T, **and** the due day at 09:00 |
| Same day at time T | One reminder, on the due day at T (it replaces the 09:00 one, never two on a day) |
| Reminders off | None. "Off" still means off. |

- Before this, the due-day reminder followed the item's time, so an item set to 6:30 PM was only reminded in the evening. `planReminders` now uses `defaultReminderMinuteOfDay` (09:00) for the due-day reminder whenever the chosen reminder is on an earlier day.
- Notification ids do not depend on the time, so the existing reconciliation (§ReminderSync) moves already-scheduled due-day reminders of existing items from their old time to 09:00 on the next launch. No migration, no new notification type, no new permission. Reminders whose time has passed are still left out.
- The item screen shows them as two rows, **Reminder 1** "3 days before at 6:30 PM" and **Reminder 2** "On the day at 9:00 AM". "Same day" and "Off" are a single **Reminder** row, as before.
- Not changed: paused, cancelled and overdue items have no reminders; free trials say "trial ends in N days" for the early one and "due today" for the day itself.
- Not done: making the due-day reminder independent of the Reminders switch. If wanted, the switch would need to be renamed to control only the early reminder.

---

# 100. Bigger service list and bills (as built)

Quick Add and the add form suggest services from `serviceCatalog` (code, `service_catalog.dart`), not from the database. The list grew from 18 to 113 entries:

| Group | Added | Examples |
| --- | --- | --- |
| Subscriptions | 64 | Peacock, Crunchyroll, Xbox Game Pass, DStv, Canal+, Claude Pro, GitHub, NordVPN, Duolingo, Coursera, Calm, Strava, Shopify, Uber One |
| Bills | 31 | Rent, Mortgage, Electricity, Water, Gas, Internet, Mobile phone, Health/Car/Home insurance, School fees, Tuition, Childcare, Student loan, Credit card |

- `CatalogService` gained `type` (subscription by default, bill for the new generic entries). Bills sit in the seeded categories people would look in (Electricity and Water in Utilities, Rent and Mortgage in Housing, insurance in Insurance, tuition in Education). No schema change and no new categories.
- Picking a suggestion in the add form sets the Subscription/Bill switch to the service's type. In Quick Add, a bill suggestion is saved as a bill, whether tapped or typed in full ("water"). A custom name stays a subscription.
- New entries have no logo (letter tile), like Hulu and Dropbox: bills are generic, and brand logos need a license check (`assets/logos/LICENSES.md`). Adding one later is a file plus a `logoAsset`.
- Keys are permanent identifiers stored in `logo_key`. The catalog test checks that keys and names are unique, categories exist, bills carry no logo and brands stay subscriptions.
- Existing items whose name matches a new entry exactly (ignoring case) get its key and, if they had none, its category on the next launch, through the existing catalog backfill. Their type is never changed.
- Not done: aliases (searching "electric" works because search matches part of a name, but "power" does not find Electricity), regional providers (MTN, Airtel, WASAC, EUCL and the like), logos for the new entries, and a "recently used" list.

---

# 101. Suggestion list and default icon (as built)

The matches shown under the name field in Quick Add and the add form were plain text. Each is now a row in a rounded card (`shared/widgets/service_suggestions.dart`, used by both places):

| Part | What it shows |
| --- | --- |
| Icon (36 dp) | The service's logo, or the Trackly mark when there is none, or the category icon for a generic bill |
| Title | The service name |
| Subtitle | Its category (Entertainment, Utilities, Housing...) |
| Tag | **Bill** on bills, nothing on subscriptions |

- Rows are `ListTile`s, 56 dp tall, so the tap target and screen-reader behaviour are the standard ones.
- **Default icon.** `ServiceIcon` (§ service icons) used a letter tile for a catalog service without a logo. It now draws the Trackly mark (`assets/illustrations/trackly_logo.svg`) in one muted color on the same tile, so it works in both themes and every icon in a list still shares one shape. This applies everywhere `ServiceIcon` is used (Home rows, lists, item screen), not only in suggestions.
- **Generic bills** (Rent, Water, Electricity...) keep the **category icon** (home, bolt...) instead of the mark: it says more than a brand stand-in. A custom item that is not in the catalog keeps its category icon as before.
- Not done: a bundled one-color "T" glyph drawn for small sizes (the mark is the full logo silhouette, so its detail is lost below about 28 dp), and logos for the 95 new entries.

---

# 102. Logos for the new services (as built)

44 of the services added in §100 now have their own logo, found and bundled the same way as the first 12: from the two CC0 collections, **gilbarbara/logos** (full-color marks) and **Simple Icons** (single-color marks, filled with the brand color from `simple-icons.json`). Each file is `assets/logos/<key>.svg` and is credited in `assets/logos/LICENSES.md`.

| Result | Count | Examples |
| --- | --- | --- |
| Has a logo | 56 in all (12 before) | GitHub, Slack, Zoom, Figma, Notion, Dropbox, Claude, Perplexity, Twitch, Deezer, Audible, Duolingo, Coursera, Strava, Shopify, 1Password, NordVPN, Mailchimp |
| Brand with no usable logo | 23 | Hulu, Disney+, Amazon Prime, Canva, Xbox Game Pass, Peacock, DStv, Showmax, Apple One, Babbel, Calm |
| Generic (no logo by design) | 34 | The 31 bills, plus Gym membership, Domain name, Web hosting |

- A brand without a logo shows the Trackly mark (§101). A **generic** entry shows its **category icon** instead (a house for Rent, a bolt for Electricity, a dumbbell for Gym membership): `CatalogService.isGeneric` is true for every bill and for the entries marked `generic`.
- Left out on purpose because they would look wrong at 36 dp: DAZN (a near-white mark that disappears on a light page), Google Workspace (only a small wordmark exists), YouTube TV (text too small to read). They keep the Trackly mark.
- Marks that are only black (Apple Arcade, GitHub, The New York Times, Peloton, Squarespace, Tidal, Uber, Medium, Midjourney) are recolored to pure black and flagged `blackMark`, so they turn white on a dark page like Apple TV+ and Max. The tests check the flag against the file's colors.
- Same safety checks as before: no scripts, images or external links, each file under 20 kB, every file used, every file credited. The 44 files add about 150 kB to the app.
- LinkedIn Learning uses the LinkedIn mark, Claude Pro the Claude mark, PlayStation Plus the PlayStation mark, and so on, like ChatGPT Plus uses the OpenAI mark. The CC0 license covers the files, not the brands; check each company's brand guidelines before a store release.
