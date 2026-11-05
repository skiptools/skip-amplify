// Copyright 2023–2026 Skip
#if !SKIP_BRIDGE
import Foundation
#if !SKIP
@preconcurrency import Amplify
import AWSCognitoAuthPlugin
#else
import SkipUI
import com.amplifyframework.kotlin.core.__
import com.amplifyframework.core.plugin.__
import com.amplifyframework.auth.__
import com.amplifyframework.auth.options.__
import com.amplifyframework.auth.cognito.options.__
import com.amplifyframework.auth.cognito.__
#endif


public struct AuthCognitoTokens {
    public var idToken: String
    public var accessToken: String
    public var refreshToken: String
}

public class SkipAmplify: @unchecked Sendable {
    
    /// Adds the AWS Cognito Auth plugin to Amplify.
    /// Call this before `configure()`.
    ///
    /// Example:
    /// ```swift
    /// try SkipAmplify.addCognitoAuthPlugin()
    /// try SkipAmplify.configure()
    /// ```
    public static func addCognitoAuthPlugin() throws {
        #if !SKIP
        try Amplify.add(plugin: AWSCognitoAuthPlugin())
        #else
        try Amplify.addPlugin(AWSCognitoAuthPlugin())
        #endif
    }
    
    // Add more plugin methods as needed, e.g.:
    //
    // public static func addPinpointAnalyticsPlugin() throws {
    //     #if !SKIP
    //     try Amplify.add(plugin: AWSPinpointAnalyticsPlugin())
    //     #else
    //     try Amplify.addPlugin(com.amplifyframework.analytics.pinpoint.AWSPinpointAnalyticsPlugin())
    //     #endif
    // }
    //
    // public static func addS3StoragePlugin() throws {
    //     #if !SKIP
    //     try Amplify.add(plugin: AWSS3StoragePlugin())
    //     #else
    //     try Amplify.addPlugin(com.amplifyframework.storage.s3.AWSS3StoragePlugin())
    //     #endif
    // }
    
    /// Configures Amplify with the plugins that have been added via `add(plugin:)`.
    /// Make sure to add all required plugins before calling this method.
    public static func configure() throws {
        #if !SKIP
        try Amplify.configure()
        #else
        try Amplify.configure(ProcessInfo.processInfo.androidContext)
        #endif
    }

    public static func recordAnalyticsEvent(name: String, properties: [String: String]) {
        #if !SKIP
        let event = BasicAnalyticsEvent(name: name, properties: properties)
        Amplify.Analytics.record(event: event)
        #else
        var builder = com.amplifyframework.analytics.AnalyticsEvent.builder().name(name)
        for (key, value) in properties {
            builder = builder.addProperty(key, value)
        }
        let event = builder.build()
        Amplify.Analytics.recordEvent(event)
        #endif
    }

    public static func signUp(username: String, password: String) async throws -> AuthSignUpResult {
        #if !SKIP
        try await Amplify.Auth.signUp(
            username: username,
            password: password,
            options: .init(
                userAttributes: [
                    //.email("user@example.com"),
                    //.name("John Doe")
                ]
            )
        )
        #else
        // see: https://docs.amplify.aws/android/start/kotlin-coroutines/
        AuthSignUpResult(platformValue: Amplify.Auth.signUp(
            username,
            password,
            AuthSignUpOptions.builder()
                //.userAttribute(AuthUserAttributeKey.email(), "user@example.com")
                //.userAttribute(AuthUserAttributeKey.name(), "John Doe")
                .build()
        ))
        #endif
    }
    
    public static func signInWithWebUI(for provider: AuthProvider) async throws -> AuthSignInResult {
        #if !SKIP
        try await Amplify.Auth.signInWithWebUI(for: provider, presentationAnchor: nil)
        #else
        let activity = UIApplication.shared.androidActivity!
        // see: https://docs.amplify.aws/android/start/kotlin-coroutines/
        AuthSignInResult(Amplify.Auth.signInWithSocialWebUI(
            provider.toJavaObject(),
            activity
        ))
        #endif
    }
    
    public static func signout() async {
        #if !SKIP
        await Amplify.Auth.signOut()
        #else
        Amplify.Auth.signOut()
        #endif
    }
    
    public static func getCredentials() async throws -> AuthCognitoTokens {
        #if !SKIP
        if let session = try await Amplify.Auth.fetchAuthSession() as? AWSAuthCognitoSession {
            switch session.getCognitoTokens() {
            case let .success(tokens):
                return .init(idToken: tokens.idToken, accessToken: tokens.accessToken, refreshToken: tokens.refreshToken)
            case let .failure(error):
                throw error
            }
        }
        #else
        var session = Amplify.Auth.fetchAuthSession() as AWSCognitoAuthSession
        
        if (session.isSignedIn) {
            if let tokens = session.userPoolTokensResult.getValue() {
                return .init(idToken: tokens.idToken!, accessToken: tokens.accessToken!, refreshToken: tokens.refreshToken!)
            }
            throw AuthenticationError.noCredentials
        }
        #endif
        throw AuthenticationError.noCredentials
    }
}

public enum AuthenticationError: Error {
    case noCredentials
}

#if SKIP
public class AuthSignInResult: Equatable, KotlinConverting<com.amplifyframework.auth.result.AuthSignInResult> {
    /// https://github.com/aws-amplify/amplify-android/blob/main/core/src/main/java/com/amplifyframework/auth/result/AuthSignInResult.java
    public let platformValue: com.amplifyframework.auth.result.AuthSignInResult
    
    public init(_ platformValue: com.amplifyframework.auth.result.AuthSignInResult) {
        self.platformValue = platformValue
    }
    
    // Bridging this function creates a Swift function that "overrides" nothing
    // SKIP @nobridge
    public override func kotlin(nocopy: Bool = false) -> com.amplifyframework.auth.result.AuthSignInResult {
        platformValue
    }
    
    public var description: String {
        platformValue.toString()
    }
    
    public var isSignedIn: Bool {
        platformValue.isSignedIn()
    }
    
    public var getNextStep: AuthSignInStep {
        AuthSignInStep(platformValue.getNextStep())
    }
}

public enum AuthSignInStep: Equatable {
    public init(_ platformValue: com.amplifyframework.auth.result.step.AuthNextSignInStep) {
        switch platformValue.getSignInStep() {
//        case com.amplifyframework.auth.result.step.AuthSignInStep.CONFIRM_SIGN_IN_WITH_SMS_MFA_CODE:
//            self = .confirmSignInWithSMSMFACode(AuthCodeDeliveryDetails, nil)
//        case com.amplifyframework.auth.result.step.AuthSignInStep.CONFIRM_SIGN_IN_WITH_CUSTOM_CHALLENGE:
//            self = .confirmSignInWithCustomChallenge(nil) // TODO
//        case com.amplifyframework.auth.result.step.AuthSignInStep.CONFIRM_SIGN_IN_WITH_NEW_PASSWORD:
//            self = .confirmSignInWithNewPassword(nil) // TODO
//        case com.amplifyframework.auth.result.step.AuthSignInStep.RESET_PASSWORD:
//            self = .resetPassword(nil) // TODO
//        case com.amplifyframework.auth.result.step.AuthSignInStep.CONFIRM_SIGN_UP:
//            self = .confirmSignUp(nil) // TODO
//        case com.amplifyframework.auth.result.step.AuthSignInStep.CONTINUE_SIGN_IN_WITH_MFA_SETUP_SELECTION:
//            self = .continueSignInWithMFASetupSelection(AllowedMFATypes) // TODO
//        case com.amplifyframework.auth.result.step.AuthSignInStep.CONTINUE_SIGN_IN_WITH_TOTP_SETUP:
//            self = .continueSignInWithTOTPSetup(TOTPSetupDetails) // TODO
        case com.amplifyframework.auth.result.step.AuthSignInStep.CONTINUE_SIGN_IN_WITH_EMAIL_MFA_SETUP:
            self = .continueSignInWithEmailMFASetup
//        case com.amplifyframework.auth.result.step.AuthSignInStep.CONTINUE_SIGN_IN_WITH_MFA_SELECTION:
//            self = .continueSignInWithMFASelection(AllowedMFATypes) // TODO
        case com.amplifyframework.auth.result.step.AuthSignInStep.CONFIRM_SIGN_IN_WITH_TOTP_CODE:
            self = .confirmSignInWithTOTPCode
//        case com.amplifyframework.auth.result.step.AuthSignInStep.CONTINUE_SIGN_IN_WITH_FIRST_FACTOR_SELECTION:
//            self = .continueSignInWithFirstFactorSelection(AvailableAuthFactorTypes) // TODO
//        case com.amplifyframework.auth.result.step.AuthSignInStep.CONFIRM_SIGN_IN_WITH_OTP:
//            self = .confirmSignInWithOTP(AuthCodeDeliveryDetails) // TODO
        case com.amplifyframework.auth.result.step.AuthSignInStep.CONFIRM_SIGN_IN_WITH_PASSWORD:
            self = .confirmSignInWithPassword
        case com.amplifyframework.auth.result.step.AuthSignInStep.DONE:
            self = .done
        default:
            self = .done
        }
    }

    /// Auth step is SMS multi factor authentication.
    ///
    /// Confirmation code for the MFA will be send to the provided SMS.
//    case confirmSignInWithSMSMFACode(AuthCodeDeliveryDetails, AdditionalInfo?)

    /// Auth step is in a custom challenge depending on the plugin.
    ///
//    case confirmSignInWithCustomChallenge(AdditionalInfo?)

    /// Auth step required the user to give a new password.
    ///
//    case confirmSignInWithNewPassword(AdditionalInfo?)

    /// Auth step required the user to give a password.
    ///
    case confirmSignInWithPassword

    /// Auth step is TOTP multi factor authentication.
    ///
    /// Confirmation code for the MFA will be retrieved from the associated Authenticator app
    case confirmSignInWithTOTPCode

    /// Auth step is for continuing sign in by setting up TOTP multi factor authentication.
    ///
//    case continueSignInWithTOTPSetup(TOTPSetupDetails)

    /// Auth step is for continuing sign in by selecting multi factor authentication type
    ///
//    case continueSignInWithMFASelection(AllowedMFATypes)

    /// Auth step is for continuing sign in by setting up EMAIL multi factor authentication.
    ///
    case continueSignInWithEmailMFASetup

    /// Auth step is for continuing sign in by selecting multi factor authentication type to setup
    ///
//    case continueSignInWithMFASetupSelection(AllowedMFATypes)

    /// Auth step is for confirming sign in with OTP
    ///
    /// OTP for the factor will be sent to the delivery medium.
    case confirmSignInWithOTP(AuthCodeDeliveryDetails)

    /// Auth step is for continuing sign in by selecting the first factor that would be used for signing in
    ///
//    case continueSignInWithFirstFactorSelection(AvailableAuthFactorTypes)

    /// Auth step required the user to change their password.
    ///
//    case resetPassword(AdditionalInfo?)

    /// Auth step that required the user to be confirmed
    ///
//    case confirmSignUp(AdditionalInfo?)

    /// There is no next step and the signIn flow is complete
    ///
    case done
}


public enum AuthProvider: Equatable {
    
    public func toJavaObject() -> com.amplifyframework.auth.AuthProvider {
        switch self {
        case .amazon:
            return com.amplifyframework.auth.AuthProvider.amazon()
        case .apple:
            return com.amplifyframework.auth.AuthProvider.apple()
        case .facebook:
            return com.amplifyframework.auth.AuthProvider.facebook()
        case .google:
            return com.amplifyframework.auth.AuthProvider.google()
        case .twitter:
            return com.amplifyframework.auth.AuthProvider.custom("twitter")
        case .custom(let providerName):
            return com.amplifyframework.auth.AuthProvider.custom(providerName)
        case .oidc(let providerName):
            return com.amplifyframework.auth.AuthProvider.custom(providerName)
        case .saml(let providerName):
            return com.amplifyframework.auth.AuthProvider.custom(providerName)
        }
    }
    
    public init(_ platformValue: com.amplifyframework.auth.AuthProvider) {
        switch platformValue.getProviderKey() {
        case "amazon":
            self = .amazon
        case "apple":
            self = .apple
        case "facebook":
            self = .facebook
        case "google":
            self = .google
        default:
            self = .custom(platformValue.getProviderKey())
        }
    }
    
    public typealias ProviderName = String

    /// Auth provider that uses Login with Amazon
    case amazon

    /// Auth provider that uses Sign in with Apple
    case apple

    /// Auth provider that uses Facebook Login
    case facebook

    /// Auth provider that uses Google Sign-In
    case google

    /// Auth provider that uses Twitter Sign-In
    case twitter

    /// Auth provider that uses OpenID Connect Protocol
    case oidc(ProviderName)

    /// Auth provider that uses Security Assertion Markup Language standard
    case saml(ProviderName)

    /// Custom auth provider that is not in this list, the associated string value will be the identifier used by
    /// the plugin service.
    case custom(ProviderName)
}

//extension AuthProvider: Codable { }



public class AuthSignUpResult: Equatable, KotlinConverting<com.amplifyframework.auth.result.AuthSignUpResult> {
    /// https://github.com/aws-amplify/amplify-android/blob/main/core/src/main/java/com/amplifyframework/auth/result/AuthSignUpResult.java
    public let platformValue: com.amplifyframework.auth.result.AuthSignUpResult

    public init(_ platformValue: com.amplifyframework.auth.result.AuthSignUpResult) {
        self.platformValue = platformValue
    }

    // Bridging this function creates a Swift function that "overrides" nothing
    // SKIP @nobridge
    public override func kotlin(nocopy: Bool = false) -> com.amplifyframework.auth.result.AuthSignUpResult {
        platformValue
    }

    public var description: String {
        platformValue.toString()
    }

    public var isSignUpComplete: Bool {
        platformValue.isSignUpComplete
    }

    public var userID: String? {
        platformValue.getUserId()
    }

    public var nextStep: AuthSignUpStep {
        AuthSignUpStep(platformValue.getNextStep())
    }
}

// Adaptation of:
// https://github.com/aws-amplify/amplify-android/blob/main/core/src/main/java/com/amplifyframework/auth/result/step/AuthSignUpStep.java
// to:
// https://github.com/aws-amplify/amplify-swift/blob/main/Amplify/Categories/Auth/Models/AuthNextSignUpStep.swift
public enum AuthSignUpStep: Equatable {
    public init(_ platformValue: com.amplifyframework.auth.result.step.AuthNextSignUpStep) {
        switch platformValue.getSignUpStep() {
        case com.amplifyframework.auth.result.step.AuthSignUpStep.CONFIRM_SIGN_UP_STEP:
            self = .confirmUser()
        case com.amplifyframework.auth.result.step.AuthSignUpStep.COMPLETE_AUTO_SIGN_IN:
            self = .completeAutoSignIn("") // TODO
        case com.amplifyframework.auth.result.step.AuthSignUpStep.DONE:
            self = .done
        }
    }

    public typealias AdditionalInfo = [String: String]
    public typealias UserId = String
    public typealias Session = String

    /// Need to confirm the user
    case confirmUser(
        AuthCodeDeliveryDetails? = nil,
        AdditionalInfo? = nil,
        UserId? = nil)

    /// Sign Up successfully completed
    /// The customers can use this step to determine if they want to complete sign in
    case completeAutoSignIn(Session)

    /// Sign up is complete
    case done

}

public class AuthCodeDeliveryDetails: Equatable, KotlinConverting<com.amplifyframework.auth.AuthCodeDeliveryDetails> {
    /// https://github.com/aws-amplify/amplify-android/blob/main/core/src/main/java/com/amplifyframework/auth/AuthCodeDeliveryDetails.java
    public let platformValue: com.amplifyframework.auth.AuthCodeDeliveryDetails

    public init(_ platformValue: com.amplifyframework.auth.AuthCodeDeliveryDetails) {
        self.platformValue = platformValue
    }

    // Bridging this function creates a Swift function that "overrides" nothing
    // SKIP @nobridge
    public override func kotlin(nocopy: Bool = false) -> com.amplifyframework.auth.AuthCodeDeliveryDetails {
        platformValue
    }

    public var description: String {
        platformValue.toString()
    }

    public var destination: String {
        platformValue.getDestination()
    }

    // TODO: map https://github.com/aws-amplify/amplify-android/blob/main/core/src/main/java/com/amplifyframework/auth/AuthUserAttributeKey.java to https://github.com/aws-amplify/amplify-swift/blob/main/Amplify/Categories/Auth/Models/AuthUserAttribute.swift
    public var attributeKey: String? {
        platformValue.getAttributeName()
    }
}

#endif

#endif

extension AuthSignInResult: @unchecked Sendable {}
