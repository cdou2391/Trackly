# Google Play: Data safety and related forms (Trackly)

Notes for completing the Play Console forms for Trackly. **Verify every answer against Google's current form and guides before submitting**: the wording changes, and the answers must match the app and the privacy policy (`docs/privacy/trackly-privacy-policy.md`). The person who submits is responsible for their accuracy.

## What the app does (the facts the answers rest on)

| Fact | Detail |
| --- | --- |
| Account | None. No sign-in. |
| User-entered data | Subscriptions, bills, payments, notes and settings stay in a database on the phone. Never sent to a server. |
| Usage analytics | Firebase Analytics (Google), **only if the person agrees** (first-run screen, or Settings > Privacy). Events with item type, frequency, currency code, trial flag, theme, counts. No names, amounts, notes or search text. Random per-install identifier; approximate region from network. Retention 14 months. |
| Crash reports | Sentry, **only if the person agrees**; Sentry is not started otherwise. Technical error details, app version, device model, OS version, language. `sendDefaultPii = false` (no IP, name or email). Database error text is scrubbed of the values being written (`lib/core/error/error_scrubber.dart`). Retention 90 days. |
| Advertising | None. The advertising ID permissions are removed from the manifest, ad ID collection and ad personalization are disabled for Analytics, and the build fails if the APK requests them (`tool/apk_lacks_permission.sh`). |
| Permissions | Notifications, internet, restart reminders after boot, vibration. |
| Export | The user creates CSV files and shares them wherever they choose. |

## Privacy policy

- URL for the Play Console field **and** the in-app link: `https://corecrest.tech/trackly/privacy-policy` (set in `lib/core/config/app_links.dart`).
- It must be live, public, not a PDF, and name the developer. Publish it **before** submitting the listing, and keep the address permanent.
- Source text and an HTML copy for the website: `docs/privacy/`.

## Data safety form (suggested answers)

Google's own guide for what to declare for Firebase is the reference: <https://firebase.google.com/docs/android/play-data-disclosure>. Check Sentry's equivalent guidance too.

| Question | Suggested answer | Why |
| --- | --- | --- |
| Does the app collect or share any user data? | **Yes** | Analytics and crash reports leave the device. |
| Is all data encrypted in transit? | **Yes** | Firebase and Sentry use HTTPS. |
| Can users request that data be deleted? | **Yes**, by email to info@corecrest.tech | Required when data is collected. Also say uninstalling resets the identifier. |
| App activity (app interactions) | Collected; purpose **Analytics** | Firebase events. |
| App info and performance (crash logs, diagnostics) | Collected; purpose **Analytics** / **App functionality** | Sentry reports. |
| Device or other IDs | Collected; purpose **Analytics** | Firebase's random app-instance ID. Confirm against the Firebase guide. |
| Location (approximate) | Check the Firebase guide | Firebase derives region from the network address. |
| Financial info | **Not collected** | Subscription amounts never leave the phone. The only financial-adjacent value sent is a currency code. |
| Personal info, contacts, photos, files, messages, audio, health | **Not collected** | |
| Shared with third parties? | **No**, if Google and Sentry are declared as service providers acting on our behalf | Play exempts transfers to service providers. Confirm against the current definition. |
| Is data collection optional for users? | **Yes**: asked on first launch (nothing is sent before the answer), changeable at any time in Settings > Privacy | See `lib/features/privacy/` and technical doc section 96. |

## Other forms

- **Advertising ID declaration:** answer that the app does **not** use the advertising ID. The manifest and CI enforce this.
- **Ads:** the app contains no ads.
- **Content rating, target audience:** target adults; not designed for children.
- **Financial features declaration:** Trackly tracks the user's own subscriptions. It does not process payments, give loans or advice. Answer accordingly.
- **Account deletion:** not applicable, there are no accounts.
