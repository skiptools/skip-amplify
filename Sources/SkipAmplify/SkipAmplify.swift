// SPDX-License-Identifier: LGPL-3.0-only WITH LGPL-3.0-linking-exception
#if !SKIP_BRIDGE
import Foundation
#if !SKIP
@preconcurrency import Amplify
#else
import com.amplifyframework.kotlin.core.__
import com.amplifyframework.auth.__
import com.amplifyframework.auth.options.__
#endif

public class SkipAmplify {
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
}

#if SKIP
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
