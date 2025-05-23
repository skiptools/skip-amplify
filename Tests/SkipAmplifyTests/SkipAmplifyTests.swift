// SPDX-License-Identifier: LGPL-3.0-only WITH LGPL-3.0-linking-exception
import XCTest
import OSLog
import Foundation
@testable import SkipAmplify

let logger: Logger = Logger(subsystem: "SkipAmplify", category: "Tests")

@available(macOS 13, *)
final class SkipAmplifyTests: XCTestCase {
    var apiValidation = true

    func testAmplifyAPI() async throws {
        logger.log("running testSkipAmplify")
        XCTAssertEqual(1 + 2, 3, "basic test")
        if apiValidation {
            throw XCTSkip("test only exists to validate API parity")
        }

        let result = try await SkipAmplify.signUp(username: "user", password: "pass")
        XCTAssertEqual("user", result.userID)
        XCTAssertEqual(false, result.isSignUpComplete)
        switch result.nextStep {
        case .confirmUser(let details, let info, let id):
            let _ = info
            let _ = id
            let _ = details?.destination
            let _ = details?.attributeKey
            break
        case .completeAutoSignIn(let session):
            break
        case .done:
            break
        }
    }

}
