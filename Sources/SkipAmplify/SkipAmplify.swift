// SPDX-License-Identifier: LGPL-3.0-only WITH LGPL-3.0-linking-exception
#if !SKIP_BRIDGE
import Foundation
#if !SKIP
@preconcurrency import Amplify
#else
import com.amplifyframework.kotlin.core.__
import com.amplifyframework.auth.__
import com.amplifyframework.auth.options.__
import com.amplifyframework.auth.result.__
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

    // SKIP @nobridge
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
        Amplify.Auth.signUp(
            username,
            password,
            AuthSignUpOptions.builder()
                //.userAttribute(AuthUserAttributeKey.email(), "user@example.com")
                //.userAttribute(AuthUserAttributeKey.name(), "John Doe")
                .build()
        )
        #endif

    }
}
#endif
