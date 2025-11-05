//
//  Certificate.swift
//  GoodNetworking
//
//  Created by te075262 on 30/10/2025.
//

import Foundation

/// Describes how a server certificate should be handled during trust evaluation.
///
/// Returned by `Certificate.certificateDisposition(using:)` to instruct the library
/// on whether to use custom certificates, system trust, or deny the connection.
///
/// Typical use cases:
/// - SSL pinning by validating certificates or public keys
/// - Trusting self-signed certificates
/// - Fallback to system trust evaluation
public enum CertificateDisposition: Sendable {

    /// Evaluate trust using the provided certificate(s).
    ///
    /// The library will:
    /// 1. Restrict the trust evaluation to these certificates as anchors.
    /// 2. Evaluate the server trust using `SecTrustEvaluateWithError`.
    /// 3. Proceed only if the evaluation succeeds.
    ///
    /// - Parameter certificates: One or more certificates to use for trust evaluation.
    ///
    /// Use this when:
    /// - Implementing certificate or public-key pinning
    /// - Using self-signed or non-system certificates
    case evaluate(certificates: [SecCertificate])

    /// Defer to system trust evaluation.
    ///
    /// The library will perform the default trust evaluation and ignore any
    /// custom certificate logic from this protocol implementation.
    ///
    /// Use this when:
    /// - No custom validation is required
    /// - You want to rely on the system trust store
    case useSystemTrustEvaluation

    /// Deny the authentication challenge.
    ///
    /// The library will reject the connection immediately.
    ///
    /// - Parameter reason: Optional description of why the connection is denied, useful for logging or debugging.
    ///
    /// Use this when:
    /// - Validation fails (e.g., pin mismatch, expired certificate)
    /// - Security policy mandates refusal
    case deny(reason: String? = nil)

}

/// Provides a strategy for validating server certificates.
///
/// Implementers may perform asynchronous operations (e.g., loading a certificate
/// from disk or network) and decide whether to:
/// - Evaluate using custom certificates
/// - Use system trust
/// - Deny the connection
public protocol Certificate: Sendable {

    /// Determines how the server trust should be handled for a connection.
    ///
    /// - Parameter serverTrust: The `SecTrust` object provided by the system.
    ///   Implementations may inspect it to perform pinning or other validations.
    ///
    /// - Returns: A `CertificateDisposition` indicating the desired action:
    ///   `.evaluate(certificates:)` to perform custom evaluation,
    ///   `.useSystemTrustEvaluation` to defer to system handling,
    ///   `.deny(reason:)` to reject the connection.
    ///
    /// - Throws: If an unrecoverable error occurs (e.g., certificate failed to load),
    ///   implementations may throw to fail the authentication challenge.
    ///
    /// ### Example Implementations
    ///
    /// **Pinned certificate from bundle**
    /// ```swift
    /// func certificateDisposition(using serverTrust: SecTrust) async throws -> CertificateDisposition {
    ///     let certificate = try loadPinnedCertificate()
    ///     return .evaluate(certificates: [certificate])
    /// }
    /// ```
    ///
    /// **Public key pinning with fallback**
    /// ```swift
    /// func certificateDisposition(using serverTrust: SecTrust) async throws -> CertificateDisposition {
    ///     guard publicKeyMatches(serverTrust) else { return .deny(reason: "Public key mismatch") }
    ///     return .useSystemTrustEvaluation
    /// }
    /// ```
    ///
    /// **Load certificate remotely**
    /// ```swift
    /// func certificateDisposition(using serverTrust: SecTrust) async throws -> CertificateDisposition {
    ///     let cert = try await downloadCertificate()
    ///     return .evaluate(certificates: [cert])
    /// }
    /// ```
    func certificateDisposition(using serverTrust: SecTrust) async throws -> CertificateDisposition

}

/// Default implementation with no specific behaviour
public struct NoPinnedCertificate: Certificate {

    public init() {}

    public func certificateDisposition(using serverTrust: SecTrust) async throws -> CertificateDisposition {
        return .useSystemTrustEvaluation
    }

}
