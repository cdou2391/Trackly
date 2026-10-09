# Trackly

A local-first mobile app for tracking subscriptions, recurring bills and free trials.

Trackly answers one question: **what is charging me next, and how much am I spending every month?**

## Features (v1 scope)

- Subscriptions, recurring bills and free trials in one model
- Quick Add from the home screen, plus a full add/edit form
- Upcoming charges, with a calendar/agenda view
- Local reminders before renewals and when trials end
- Manual payment recording and payment history
- Monthly and annual cost summary, grouped per currency
- Pause, cancel and delete
- Basic insights and category breakdown
- Dark and light themes

## Principles

- **Local-first:** all data stays on the device, in a local database.
- **No account, no backend:** nothing to sign up for, and it works offline.
- **No bank access:** no card, bank, SMS or email integration. Entries are manual.
- **Intentionally small:** it is a recurring-payment tracker, not a budgeting app.

## Tech stack

- Flutter, Dart and Material 3
- Riverpod for state management
- GoRouter for navigation
- Drift on SQLite for local storage
- `flutter_local_notifications` and `timezone` for on-device reminders
- Firebase Analytics for anonymous usage events, and Sentry for crashes and errors

## Status

Early planning. No application code yet.

## License

TBD
