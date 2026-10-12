# Release signing

Android installs a new version over an old one only if both are signed with
the **same key**. Uninstalling instead deletes the app's local data, and
Trackly keeps everything on the device. So every release is signed with one
permanent key, created once.

**Losing this key means no release can ever update an installed copy.** Back it
up in two places (a password manager and an offline copy) before using it.

## One-time setup

### 1. Create the key (on your own machine)

```bash
keytool -genkeypair -v \
  -keystore trackly-release.jks \
  -alias trackly \
  -keyalg RSA -keysize 4096 -validity 10000
```

Pick a strong password and use it for both the keystore and the key (the
default PKCS12 format uses one password for both). Answer the name questions
however you like. Never commit the `.jks` file; `*.jks`, `*.keystore` and
`android/key.properties` are already gitignored.

### 2. Add four repository secrets

GitHub, then Settings, Secrets and variables, Actions, New repository secret:

| Secret | Value |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | the keystore, base64 on one line: `base64 -w0 trackly-release.jks` (macOS: `base64 -i trackly-release.jks \| tr -d '\n'`) |
| `ANDROID_KEYSTORE_PASSWORD` | the password you chose |
| `ANDROID_KEY_ALIAS` | `trackly` |
| `ANDROID_KEY_PASSWORD` | the same password |

With the GitHub CLI: `gh secret set ANDROID_KEYSTORE_BASE64 < <(base64 -w0 trackly-release.jks)`.

### 3. Publish

Run the **Release APK** workflow from the Actions tab on `main` with a new tag
such as `v1.0.0-preview.2`. If a secret is missing it fails in seconds with the
name of the secret; it never publishes a debug-signed build.

The release notes show the signing certificate's SHA-256. It must be identical
on every release.

## If the release fails at "Restore and check the release key"

The step names the problem. It never prints a secret.

| Message | Fix |
|---|---|
| value is missing or empty | Add the secret named in the message (names are exact). |
| contains N characters that are not base64 | The value was copied with extra text, such as a shell prompt, quotes or a label. |
| length is not a multiple of 4 | The value was cut off when copied. |
| not valid base64 | Set it again from the command output. |
| keystore would not open | Wrong `ANDROID_KEYSTORE_PASSWORD` or `ANDROID_KEY_ALIAS` (the alias is `trackly`). |
| PKCS12 keystore uses one password | Set `ANDROID_KEY_PASSWORD` to the same value as `ANDROID_KEYSTORE_PASSWORD`. |

To avoid copy errors, set the keystore secret straight from the command rather
than pasting it:

```bash
base64 -w0 trackly-release.jks | gh secret set ANDROID_KEYSTORE_BASE64 --repo cdou2391/Trackly
```

To check the value you intend to store is intact before setting it:

```bash
base64 -w0 trackly-release.jks | base64 -d | cmp - trackly-release.jks && echo OK
```

When the step passes, the log shows the key's SHA-256 fingerprint. It must match
the `SHA256:` line from `keytool -list -v -keystore trackly-release.jks`.

## Moving from the debug-signed preview

`v1.0.0-preview.1` was signed with a throwaway debug key. Android cannot
install the first release-signed build over it, so **uninstall it once**
(this deletes its data). From then on, updates install over each other and keep
the data.

## Local release builds

Create `android/key.properties` (gitignored):

```properties
storeFile=/absolute/path/to/trackly-release.jks
storePassword=...
keyAlias=trackly
keyPassword=...
```

Then `flutter build apk --release` is signed with the release key. Without
this file it falls back to the debug key, which is fine for trying the app but
cannot update a release install.

## How it is protected

- The key lives only in repository secrets and is written to the runner's temp
  folder for the build, then deleted.
- The release workflow only runs from `main` or a `v*` tag, since it can read
  the key.
- CI on pull requests has no access to the key. It builds once without a key
  (must fall back to the debug key) and once with a throwaway key made on the
  spot (must be signed by it), which proves the signing configuration works
  without the real key.
- Stronger: put the secrets in a GitHub **environment** named `release` with a
  required reviewer, and add `environment: release` to the workflow job.

## Version codes

Each release's version code is the workflow run number, which only increases.
Android refuses to install a lower version code than the one already on the
phone, so releases must always come from this workflow.
