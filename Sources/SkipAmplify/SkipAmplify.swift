// This is free software: you can redistribute and/or modify it
// under the terms of the GNU Lesser General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

import Foundation
#if !SKIP
import Amplify
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
