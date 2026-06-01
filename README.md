# SkipAmplify

[AWS Amplify](https://aws.amazon.com/amplify/) support for dual-platform
[Skip](https://skip.dev) apps on both iOS and Android.

On iOS this wraps the [Amplify Swift SDK](https://github.com/aws-amplify/amplify-swift).
On Android, the Swift code is transpiled to Kotlin via Skip Lite and wraps the
[Amplify Android SDK](https://github.com/aws-amplify/amplify-android), exposing
a unified Swift API across both platforms.

The authoritative documentation for the underlying SDKs lives at:

- **Swift / iOS:** [docs.amplify.aws/swift/](https://docs.amplify.aws/swift/) — see also the [Amplify Swift API reference](https://aws-amplify.github.io/amplify-swift/docs/).
- **Kotlin / Android:** [docs.amplify.aws/android/](https://docs.amplify.aws/android/) — see also the [Amplify Android API reference](https://aws-amplify.github.io/amplify-android/).

When you need behavior that this wrapper does not yet expose, fall back to the
platform-specific APIs from inside `#if !SKIP` (iOS) or `#if SKIP` (Android)
blocks, using the references above.

## Setup

Add the dependency to your `Package.swift` file:

```swift
let package = Package(
    name: "my-package",
    products: [
        .library(name: "MyProduct", targets: ["MyTarget"]),
    ],
    dependencies: [
        .package(url: "https://source.skip.dev/skip-amplify.git", "0.0.0"..<"2.0.0"),
    ],
    targets: [
        .target(name: "MyTarget", dependencies: [
            .product(name: "SkipAmplify", package: "skip-amplify")
        ])
    ]
)
```

`SkipAmplify` transitively pulls in the
[`Amplify`](https://github.com/aws-amplify/amplify-swift) and
[`AWSCognitoAuthPlugin`](https://github.com/aws-amplify/amplify-swift/tree/main/AmplifyPlugins/Auth/Sources/AWSCognitoAuthPlugin)
products on Apple platforms, and adds the corresponding
`com.amplifyframework:core-kotlin` and `com.amplifyframework:aws-auth-cognito`
Gradle dependencies on Android (configured in `Sources/SkipAmplify/Skip/skip.yml`).

### Amplify Backend Configuration

You need an Amplify backend with the Auth (and optionally Analytics, Storage,
etc.) categories provisioned. Follow the Amplify Gen 2 setup steps:

- [Set up Amplify Auth (Swift)](https://docs.amplify.aws/swift/build-a-backend/auth/set-up-auth/)
- [Set up Amplify Auth (Android)](https://docs.amplify.aws/android/build-a-backend/auth/set-up-auth/)

The Amplify CLI produces an `amplify_outputs.json` file (Gen 2) or an
`amplifyconfiguration.json` file (Gen 1) that the platform SDK loads at
configure-time.

### iOS Configuration

Place the generated `amplify_outputs.json` (or `amplifyconfiguration.json`) in
the `Darwin/` folder of your Skip project so it is bundled with the iOS app.

If you use `signInWithWebUI` with a social provider, register the OAuth
callback URL scheme in your `Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>myapp</string>
        </array>
    </dict>
</array>
```

See the [Swift hosted UI guide](https://docs.amplify.aws/swift/build-a-backend/auth/add-social-provider/)
for the full list of required keys.

### Android Configuration

Place the generated `amplify_outputs.json` (or `amplifyconfiguration.json`) in
`Android/app/src/main/res/raw/` so the Android SDK can load it from the APK.

For social sign-in, register the OAuth callback scheme in
`Android/app/src/main/AndroidManifest.xml` on the activity that hosts the auth
flow:

```xml
<activity android:name=".MainActivity" ...>
    <intent-filter>
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data android:scheme="myapp" />
    </intent-filter>
</activity>
```

See the [Android hosted UI guide](https://docs.amplify.aws/android/build-a-backend/auth/add-social-provider/)
for details.

## Usage

### Configure Amplify

Add the Cognito Auth plugin and configure Amplify once at app startup —
typically from your app's `init()` or an `AppDelegate.onInit()`:

```swift
import SkipAmplify

@main struct MyApp: App {
    init() {
        do {
            try SkipAmplify.addCognitoAuthPlugin()
            try SkipAmplify.configure()
        } catch {
            print("Amplify configuration failed: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

Under the hood this calls `Amplify.add(plugin:)` + `Amplify.configure()` on iOS
([Amplify Swift / Amplify](https://aws-amplify.github.io/amplify-swift/docs/documentation/amplify/amplify/))
and `Amplify.addPlugin(...)` + `Amplify.configure(context)` on Android
([Amplify Android / Amplify](https://aws-amplify.github.io/amplify-android/reference/com/amplifyframework/core/Amplify.html)).
The Android variant requires an Android `Context`, which `SkipAmplify` obtains
automatically from `ProcessInfo.processInfo.androidContext`.

### Sign Up

Create a new Cognito user with a username and password:

```swift
let result = try await SkipAmplify.signUp(username: "user@example.com",
                                          password: "Sup3rS3cret!")

if result.isSignUpComplete {
    // The user pool didn't require confirmation
} else {
    switch result.nextStep {
    case .confirmUser(let details, let info, let userId):
        print("Confirm via \(details?.destination ?? "?") (attribute: \(details?.attributeKey ?? "?"))")
    case .completeAutoSignIn(let session):
        print("Auto sign-in available, session: \(session)")
    case .done:
        break
    }
}
```

The returned `AuthSignUpResult` wraps:

- [`AuthSignUpResult` (Swift)](https://aws-amplify.github.io/amplify-swift/docs/documentation/amplify/authsignupresult)
- [`AuthSignUpResult` (Android)](https://aws-amplify.github.io/amplify-android/reference/com/amplifyframework/auth/result/AuthSignUpResult.html)

### Sign In with a Social Provider (Hosted UI / Web UI)

Open the system browser to complete OAuth via one of Cognito's federated
identity providers:

```swift
do {
    let result = try await SkipAmplify.signInWithWebUI(for: .google)
    if result.isSignedIn {
        print("Signed in. Next step: \(result.getNextStep)")
    }
} catch {
    print("Web UI sign-in failed: \(error)")
}
```

Supported providers (`AuthProvider`):

| Case | iOS provider | Android provider |
|---|---|---|
| `.amazon` | Login with Amazon | `AuthProvider.amazon()` |
| `.apple` | Sign in with Apple | `AuthProvider.apple()` |
| `.facebook` | Facebook Login | `AuthProvider.facebook()` |
| `.google` | Google Sign-In | `AuthProvider.google()` |
| `.twitter` | (custom) | `AuthProvider.custom("twitter")` |
| `.custom(name)` | Custom provider name | `AuthProvider.custom(name)` |
| `.oidc(name)` | OIDC provider | `AuthProvider.custom(name)` |
| `.saml(name)` | SAML provider | `AuthProvider.custom(name)` |

References:

- Swift: [`Amplify.Auth.signInWithWebUI(for:presentationAnchor:)`](https://docs.amplify.aws/swift/build-a-backend/auth/sign-in/#sign-in-with-a-social-provider-hosted-ui)
- Android: [`Amplify.Auth.signInWithSocialWebUI`](https://docs.amplify.aws/android/build-a-backend/auth/sign-in/#sign-in-with-a-social-provider-hosted-ui)

### Sign Out

```swift
await SkipAmplify.signout()
```

References:

- Swift: [`Amplify.Auth.signOut()`](https://docs.amplify.aws/swift/build-a-backend/auth/sign-out/)
- Android: [`Amplify.Auth.signOut`](https://docs.amplify.aws/android/build-a-backend/auth/sign-out/)

### Retrieve Cognito Tokens

Fetch the current `idToken`, `accessToken`, and `refreshToken` for the
signed-in user. These are typically used to authorize calls to your own
backend or to AWS services:

```swift
do {
    let tokens = try await SkipAmplify.getCredentials()
    apiClient.setAuthorization("Bearer \(tokens.accessToken)")
} catch AuthenticationError.noCredentials {
    // Not signed in or session has no Cognito tokens
} catch {
    print("Token retrieval failed: \(error)")
}
```

Returned as an `AuthCognitoTokens` value with `idToken`, `accessToken`, and
`refreshToken` strings.

References:

- Swift: [`AWSAuthCognitoSession.getCognitoTokens()`](https://docs.amplify.aws/swift/build-a-backend/auth/accessing-credentials/)
- Android: [`AWSCognitoAuthSession.getUserPoolTokensResult()`](https://docs.amplify.aws/android/build-a-backend/auth/accessing-credentials/)

### Record an Analytics Event

If you have added the Analytics plugin (see [Extending with Additional Plugins](#extending-with-additional-plugins) below), you can record custom events with a name and a string-to-string property map:

```swift
SkipAmplify.recordAnalyticsEvent(
    name: "checkout_completed",
    properties: ["sku": "ABC-123", "currency": "USD"]
)
```

References:

- Swift: [`Amplify.Analytics.record(event:)`](https://docs.amplify.aws/swift/build-a-backend/more-features/analytics/record-events/)
- Android: [`Amplify.Analytics.recordEvent(event)`](https://docs.amplify.aws/android/build-a-backend/more-features/analytics/record-events/)

### Full SwiftUI Example

```swift
import SwiftUI
import SkipAmplify

struct AuthView: View {
    @State var username = ""
    @State var password = ""
    @State var status = "Signed out"

    var body: some View {
        Form {
            TextField("Username", text: $username)
                .textContentType(.emailAddress)
                .autocorrectionDisabled()
            SecureField("Password", text: $password)

            Button("Sign Up") {
                Task {
                    do {
                        let result = try await SkipAmplify.signUp(
                            username: username,
                            password: password
                        )
                        status = result.isSignUpComplete
                            ? "Sign-up complete"
                            : "Confirm account: \(result.nextStep)"
                    } catch {
                        status = "Sign-up failed: \(error.localizedDescription)"
                    }
                }
            }

            Button("Sign In with Google") {
                Task {
                    do {
                        let result = try await SkipAmplify.signInWithWebUI(for: .google)
                        status = result.isSignedIn ? "Signed in" : "Next: \(result.getNextStep)"
                    } catch {
                        status = "Sign-in failed: \(error.localizedDescription)"
                    }
                }
            }

            Button("Show Tokens") {
                Task {
                    do {
                        let tokens = try await SkipAmplify.getCredentials()
                        status = "id=\(tokens.idToken.prefix(12))…"
                    } catch {
                        status = "No credentials"
                    }
                }
            }

            Button("Sign Out") {
                Task {
                    await SkipAmplify.signout()
                    status = "Signed out"
                }
            }

            Text(status).font(.caption)
        }
    }
}
```

## API Reference

### SkipAmplify

The top-level entry point. All methods are `static`.

| Method | Description |
|---|---|
| `addCognitoAuthPlugin()` | Add the AWS Cognito Auth plugin (call before `configure()`). |
| `configure()` | Configure Amplify with the registered plugins. On Android the Android `Context` is supplied automatically. |
| `signUp(username:password:)` | Register a new Cognito user, returning an `AuthSignUpResult`. |
| `signInWithWebUI(for:)` | Open the hosted UI for the given `AuthProvider`, returning an `AuthSignInResult`. |
| `signout()` | Sign out the current user. |
| `getCredentials()` | Fetch the current `AuthCognitoTokens`, or throw `AuthenticationError.noCredentials`. |
| `recordAnalyticsEvent(name:properties:)` | Record a custom analytics event (requires an Analytics plugin to be added). |

### AuthCognitoTokens

| Property | Type | Description |
|---|---|---|
| `idToken` | `String` | OpenID Connect ID token (JWT). |
| `accessToken` | `String` | Cognito access token. |
| `refreshToken` | `String` | Cognito refresh token. |

### AuthSignUpResult

Wraps [`AuthSignUpResult` on Android](https://github.com/aws-amplify/amplify-android/blob/main/core/src/main/java/com/amplifyframework/auth/result/AuthSignUpResult.java)
and the equivalent [`AuthSignUpResult` on Swift](https://aws-amplify.github.io/amplify-swift/docs/documentation/amplify/authsignupresult).

| Property | Type | Description |
|---|---|---|
| `isSignUpComplete` | `Bool` | Whether the sign-up is fully complete. |
| `userID` | `String?` | The Cognito user ID, if assigned. |
| `nextStep` | `AuthSignUpStep` | The next step required to finish sign-up. |

### AuthSignUpStep

| Case | Description |
|---|---|
| `.confirmUser(details, info, userId)` | The user must confirm their account (typically via email/SMS code). |
| `.completeAutoSignIn(session)` | Sign-up completed; an auto sign-in session is available. |
| `.done` | Sign-up is fully complete. |

### AuthSignInResult

Wraps [`AuthSignInResult` on Android](https://github.com/aws-amplify/amplify-android/blob/main/core/src/main/java/com/amplifyframework/auth/result/AuthSignInResult.java)
and the equivalent [`AuthSignInResult` on Swift](https://aws-amplify.github.io/amplify-swift/docs/documentation/amplify/authsigninresult).

| Property | Type | Description |
|---|---|---|
| `isSignedIn` | `Bool` | Whether sign-in is fully complete. |
| `getNextStep` | `AuthSignInStep` | The next step required, if any. |

### AuthSignInStep

| Case | Description |
|---|---|
| `.confirmSignInWithPassword` | Re-enter the user's password to continue. |
| `.confirmSignInWithTOTPCode` | Enter the TOTP code from an authenticator app. |
| `.continueSignInWithEmailMFASetup` | Continue MFA setup using email. |
| `.confirmSignInWithOTP(details)` | Enter the OTP delivered via the channel described by `details`. |
| `.done` | Sign-in is complete. |

Several upstream steps (SMS MFA, custom challenge, new password, first-factor
selection, etc.) are not yet mapped — see [Limitations](#limitations).

### AuthCodeDeliveryDetails

| Property | Type | Description |
|---|---|---|
| `destination` | `String` | Where the confirmation code was delivered (email address, phone number, etc.). |
| `attributeKey` | `String?` | Which user attribute the destination corresponds to. |

### AuthProvider

A cross-platform enum mirroring the Amplify Swift [`AuthProvider`](https://aws-amplify.github.io/amplify-swift/docs/documentation/amplify/authprovider/)
type. See [Sign In with a Social Provider](#sign-in-with-a-social-provider-hosted-ui--web-ui) for the case list.

### AuthenticationError

| Case | Description |
|---|---|
| `.noCredentials` | `getCredentials()` was called while signed out, or the Cognito session contained no tokens. |

## Extending with Additional Plugins

Only the Cognito Auth plugin is registered out of the box. To add more Amplify
categories (Analytics, Storage, API, etc.), drop down to the platform-specific
APIs. The pattern matches `addCognitoAuthPlugin()` — see the commented
examples in `Sources/SkipAmplify/SkipAmplify.swift`:

```swift
public static func addPinpointAnalyticsPlugin() throws {
    #if !SKIP
    try Amplify.add(plugin: AWSPinpointAnalyticsPlugin())
    #else
    try Amplify.addPlugin(com.amplifyframework.analytics.pinpoint.AWSPinpointAnalyticsPlugin())
    #endif
}

public static func addS3StoragePlugin() throws {
    #if !SKIP
    try Amplify.add(plugin: AWSS3StoragePlugin())
    #else
    try Amplify.addPlugin(com.amplifyframework.storage.s3.AWSS3StoragePlugin())
    #endif
}
```

When you add an Amplify plugin you must also declare its Swift product in
your app's `Package.swift` (from
[`amplify-swift`](https://github.com/aws-amplify/amplify-swift))
and its Gradle artifact in your `skip.yml` (from the
[Amplify Android Maven coordinates](https://github.com/aws-amplify/amplify-android?tab=readme-ov-file#using-amplify-from-your-app)).

## Limitations

> [!NOTE]
> On iOS, the full [Amplify Swift](https://docs.amplify.aws/swift/) API is
> available through the re-exported `Amplify` and `AWSCognitoAuthPlugin`
> modules. The limitations below apply to the cross-platform Swift API exposed
> by `SkipAmplify` itself.

- **Only the Cognito Auth plugin is wired up by default.** Analytics, Storage,
  API, Predictions, Geo, DataStore, Push Notifications, and other Amplify
  categories must be added with `#if SKIP` / `#if !SKIP` branches, as shown in
  [Extending with Additional Plugins](#extending-with-additional-plugins).
- **`signUp` user attributes are not yet wrapped.** The wrapper passes no
  attributes today; if you need to set `email`, `name`, etc. on the user pool,
  edit `SkipAmplify.signUp(username:password:)` to add the appropriate
  `userAttributes` / `userAttribute(...)` calls on each platform.
- **`AuthSignInStep` mapping is partial.** SMS MFA, custom challenges, new
  password, reset password, confirm sign-up, MFA selection/setup, and
  first-factor selection cases are present in the upstream APIs but not yet
  bridged. For now, drop into a platform branch when you hit one of those
  steps.
- **`AuthCodeDeliveryDetails.attributeKey`** is exposed as the raw `String?`
  key on Android. The mapping to the strongly-typed Swift
  [`AuthUserAttributeKey`](https://aws-amplify.github.io/amplify-swift/docs/documentation/amplify/authuserattributekey)
  / Android [`AuthUserAttributeKey`](https://github.com/aws-amplify/amplify-android/blob/main/core/src/main/java/com/amplifyframework/auth/AuthUserAttributeKey.java)
  enum is not yet implemented.
- **Sign-in confirmation, password reset, and account-recovery flows** (e.g.
  `confirmSignUp`, `resendSignUpCode`, `resetPassword`, `confirmResetPassword`)
  are not yet exposed. Use the underlying SDKs directly from `#if !SKIP` /
  `#if SKIP` blocks.

PRs to fill in any of the above are welcome.

## Building

This project is a Swift Package Manager module that uses the
[Skip](https://skip.dev) plugin to build the package for both iOS and Android.

## Testing

The module can be tested using the standard `swift test` command
or by running the test target for the macOS destination in Xcode,
which will run the Swift tests as well as the transpiled
Kotlin JUnit tests in the Robolectric Android simulation environment.

Parity testing can be performed with `skip test`,
which will output a table of the test results for both platforms.

## License

This software is licensed under the
[Mozilla Public License 2.0](https://www.mozilla.org/MPL/).
