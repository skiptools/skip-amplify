# SkipAmplify

This package provides support for [AWS Amplify](https://aws.amazon.com/amplify/)
for dual-platform [Skip](https://skip.tools) projects. It provides a unified
interface for the
[Amplify Swift SDK](https://github.com/aws-amplify/amplify-swift)
and
[Amplify Kotlin SDK](https://github.com/aws-amplify/amplify-android).


This is a free [Skip](https://skip.tools) Swift/Kotlin library project containing the following modules:

SkipAmplify

## Building

This project is a free Swift Package Manager module that uses the
[Skip](https://skip.tools) plugin to transpile Swift into Kotlin.

Building the module requires that Skip be installed using
[Homebrew](https://brew.sh) with `brew install skiptools/skip/skip`.
This will also install the necessary build prerequisites:
Kotlin, Gradle, and the Android build tools.

## Testing

The module can be tested using the standard `swift test` command
or by running the test target for the macOS destination in Xcode,
which will run the Swift tests as well as the transpiled
Kotlin JUnit tests in the Robolectric Android simulation environment.

Parity testing can be performed with `skip test`,
which will output a table of the test results for both platforms.
