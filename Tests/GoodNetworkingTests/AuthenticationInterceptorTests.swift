//
//  AuthenticationInterceptorTests.swift
//  GoodNetworking
//
//  Regression tests for credential handling around a failed refresh.
//

@testable import GoodNetworking
import Testing
import Foundation

// MARK: - Test doubles

private struct TestCredential: Equatable, Sendable {

    let accessToken: String

}

/// Mutable state behind a lock.
///
/// The accessors are deliberately synchronous: `NSLock` is `noasync` under Swift 6, and the
/// `Authenticator` requirements that need this state are `async`.
private final class SpyState: @unchecked Sendable {

    private let lock = NSLock()
    private var credential: TestCredential?
    private var attempts = 0
    private var reportedFailures = 0

    init(credential: TestCredential?) {
        self.credential = credential
    }

    var storedCredential: TestCredential? {
        lock.lock()
        defer { lock.unlock() }
        return credential
    }

    var refreshAttempts: Int {
        lock.lock()
        defer { lock.unlock() }
        return attempts
    }

    var reportedFailureCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return reportedFailures
    }

    func store(_ newCredential: TestCredential?) {
        lock.lock()
        defer { lock.unlock() }
        credential = newCredential
    }

    func recordRefreshAttempt() {
        lock.lock()
        defer { lock.unlock() }
        attempts += 1
    }

    func recordReportedFailure() {
        lock.lock()
        defer { lock.unlock() }
        reportedFailures += 1
    }

}

/// Records what the interceptor does to the credential store, and lets a test decide
/// whether the refresh call succeeds or fails.
private final class SpyAuthenticator: Authenticator, @unchecked Sendable {

    typealias Credential = TestCredential

    private let state: SpyState
    private let refreshResult: Result<TestCredential, NetworkError>

    init(storing credential: TestCredential, refreshResult: Result<TestCredential, NetworkError>) {
        self.state = SpyState(credential: credential)
        self.refreshResult = refreshResult
    }

    // MARK: Observation

    var storedCredential: TestCredential? { state.storedCredential }
    var refreshAttempts: Int { state.refreshAttempts }
    var reportedFailureCount: Int { state.reportedFailureCount }

    // MARK: Authenticator

    func getCredential() async -> TestCredential? {
        state.storedCredential
    }

    func storeCredential(_ newCredential: TestCredential?) async {
        state.store(newCredential)
    }

    func apply(credential: TestCredential, to request: inout URLRequest) async throws(NetworkError) {
        request.setValue("Bearer \(credential.accessToken)", forHTTPHeaderField: "Authorization")
    }

    func refresh(credential: TestCredential) async throws(NetworkError) -> TestCredential {
        state.recordRefreshAttempt()

        switch refreshResult {
        case .success(let refreshed):
            return refreshed

        case .failure(let error):
            throw error
        }
    }

    func didRequest(_ request: inout URLRequest, failDueToAuthenticationError error: HTTPError) -> Bool {
        error.statusCode == 401
    }

    func isRequest(_ request: inout URLRequest, authenticatedWith credential: TestCredential) -> Bool {
        request.value(forHTTPHeaderField: "Authorization") == "Bearer \(credential.accessToken)"
    }

    func refresh(didFailDueToError error: HTTPError) async {
        state.recordReportedFailure()
    }

}

// MARK: - Helpers

private let endpoint = URL(string: "https://example.invalid/user/profile")!

private func makeUnauthorizedError() -> NetworkError {
    .remote(HTTPError(statusCode: 401, errorResponse: Data()))
}

/// Drives one full "request was rejected with 401, so refresh" cycle and returns the spy.
///
/// `retry` never touches the session it is handed, so an ephemeral one is enough — no
/// request leaves the process in these tests.
@discardableResult
private func runRefreshCycle(
    refreshResult: Result<TestCredential, NetworkError>,
    initial: TestCredential = TestCredential(accessToken: "original")
) async -> (authenticator: SpyAuthenticator, interceptor: AuthenticationInterceptor<SpyAuthenticator>) {
    let authenticator = SpyAuthenticator(storing: initial, refreshResult: refreshResult)
    let interceptor = AuthenticationInterceptor(authenticator: authenticator)
    let session = NetworkSession(baseUrl: "https://example.invalid", interceptor: interceptor)

    var request = URLRequest(url: endpoint)
    try? await interceptor.adapt(urlRequest: &request)

    _ = try? await interceptor.retry(urlRequest: &request, for: session, dueTo: makeUnauthorizedError())

    return (authenticator, interceptor)
}

// MARK: - Failed refresh must not destroy the credential

/// A refresh that fails for a reason unrelated to the credential's validity must leave the
/// stored credential alone.
///
/// `refresh(credential:)` currently calls `storeCredential(nil)` *before* attempting the
/// refresh, on the assumption that "current credential must be expired at this point and is
/// safe to clear". That assumption does not hold: the refresh is driven by a 401 from the
/// server, which says nothing about whether the credential is expired, and the refresh token
/// is not expired even when the access token is. A dropped connection, a 500 or a 429 is
/// therefore enough to permanently delete a recoverable session.
@Test(
    "A refresh failure unrelated to credential validity must not delete the credential",
    arguments: [nil, 500, 429] as [Int?]
)
private func failedRefreshPreservesStoredCredential(statusCode: Int?) async throws {
    let failure: NetworkError = statusCode
        .map { .remote(HTTPError(statusCode: $0, errorResponse: Data())) }
        ?? .local(URLError(.networkConnectionLost))

    let original = TestCredential(accessToken: "original")
    let (authenticator, _) = await runRefreshCycle(refreshResult: .failure(failure), initial: original)

    #expect(authenticator.refreshAttempts == 1)
    #expect(authenticator.storedCredential == original)
}

/// The user-visible consequence of the above.
///
/// Once the credential is gone, `adapt` takes the `if let credential` path and silently does
/// nothing, so every subsequent request leaves without an `Authorization` header and the
/// server answers 401 to an anonymous caller. The app looks signed in, the logs show a 401,
/// and nothing in them explains why — the token was never sent.
@Test("Requests must not silently go out unauthenticated after a failed refresh")
private func requestsStayAuthenticatedAfterFailedRefresh() async throws {
    let (_, interceptor) = await runRefreshCycle(
        refreshResult: .failure(.local(URLError(.networkConnectionLost)))
    )

    var nextRequest = URLRequest(url: endpoint)
    try? await interceptor.adapt(urlRequest: &nextRequest)

    #expect(nextRequest.value(forHTTPHeaderField: "Authorization") != nil)
}

// MARK: - Controls

/// Proves the harness drives the real code path, so a failure above cannot be blamed on it.
@Test("A successful refresh replaces the stored credential")
private func successfulRefreshStoresNewCredential() async throws {
    let refreshed = TestCredential(accessToken: "refreshed")
    let (authenticator, _) = await runRefreshCycle(refreshResult: .success(refreshed))

    #expect(authenticator.refreshAttempts == 1)
    #expect(authenticator.storedCredential == refreshed)
}

// MARK: - Concurrent refresh against a shared credential

/// One credential cell shared by several sessions.
///
/// Models a keychain item that two `AuthenticationInterceptor`s read and write. That covers
/// both shapes of the problem: several sessions inside one app (each `resolve(userId)` builds
/// its own interceptor, so they share no lock), and two devices sharing one synchronizable
/// iCloud Keychain item.
///
/// `arm(requiredReads:)` pins the interleaving that matters — every participant reads the same
/// credential before the first one clears it. Without it the outcome is timing-dependent and
/// the test would be flaky rather than wrong.
private actor SharedCredentialStore {

    private var credential: TestCredential?
    private var readsSinceArm = 0
    private var requiredReads: Int?
    private var waiters: [CheckedContinuation<Void, Never>] = []

    init(credential: TestCredential) {
        self.credential = credential
    }

    var current: TestCredential? {
        credential
    }

    func arm(requiredReads count: Int) {
        self.requiredReads = count
        self.readsSinceArm = 0
    }

    func read() -> TestCredential? {
        guard requiredReads != nil else { return credential }

        readsSinceArm += 1
        releaseWaitersIfReady()
        return credential
    }

    func write(_ newCredential: TestCredential?) async {
        if let requiredReads, readsSinceArm < requiredReads {
            await withCheckedContinuation { waiters.append($0) }
        }

        credential = newCredential
    }

    private func releaseWaitersIfReady() {
        guard let requiredReads, readsSinceArm >= requiredReads else { return }

        let pending = waiters
        waiters = []
        pending.forEach { $0.resume() }
    }

}

/// A refresh endpoint with single-use rotation and reuse detection, as the PassGate backend
/// implements it: presenting a retired token invalidates the whole family.
private actor RotatingAuthServer {

    private var validTokens: Set<String>
    private var issued = 0

    init(seed: String) {
        self.validTokens = [seed]
    }

    func accepts(_ token: String) -> Bool {
        validTokens.contains(token)
    }

    func exchange(_ token: String) throws(NetworkError) -> TestCredential {
        guard validTokens.contains(token) else {
            // Reuse detected — the backend destroys every token in the family.
            validTokens.removeAll()
            throw NetworkError.remote(HTTPError(statusCode: 401, errorResponse: Data()))
        }

        validTokens.remove(token)
        issued += 1

        let rotated = "token-\(issued)"
        validTokens.insert(rotated)
        return TestCredential(accessToken: rotated)
    }

}

private final class SharedStoreAuthenticator: Authenticator, @unchecked Sendable {

    typealias Credential = TestCredential

    private let store: SharedCredentialStore
    private let server: RotatingAuthServer

    init(store: SharedCredentialStore, server: RotatingAuthServer) {
        self.store = store
        self.server = server
    }

    func getCredential() async -> TestCredential? {
        await store.read()
    }

    func storeCredential(_ newCredential: TestCredential?) async {
        await store.write(newCredential)
    }

    func apply(credential: TestCredential, to request: inout URLRequest) async throws(NetworkError) {
        request.setValue("Bearer \(credential.accessToken)", forHTTPHeaderField: "Authorization")
    }

    func refresh(credential: TestCredential) async throws(NetworkError) -> TestCredential {
        try await server.exchange(credential.accessToken)
    }

    func didRequest(_ request: inout URLRequest, failDueToAuthenticationError error: HTTPError) -> Bool {
        error.statusCode == 401
    }

    func isRequest(_ request: inout URLRequest, authenticatedWith credential: TestCredential) -> Bool {
        request.value(forHTTPHeaderField: "Authorization") == "Bearer \(credential.accessToken)"
    }

    func refresh(didFailDueToError error: HTTPError) async {}

}

/// Two sessions sharing one credential, both reacting to a 401 at the same time.
///
/// Exactly one of them can win the rotation — that is what single-use tokens mean, and it is
/// fine. What must not happen is that the loser wipes the shared cell on its way in and stores
/// nothing on its way out, throwing away a rotation that had already succeeded.
///
/// Whether the backend then invalidates the token family because of the replayed token is a
/// property of that backend and of sharing one credential between sessions, not of this
/// interceptor, so it is deliberately not asserted here.
@Test("A losing concurrent refresh must not discard the winner's credential")
private func concurrentRefreshOnSharedCredentialKeepsUserSignedIn() async throws {
    let seed = TestCredential(accessToken: "token-0")
    let store = SharedCredentialStore(credential: seed)
    let server = RotatingAuthServer(seed: seed.accessToken)

    let sessionA = AuthenticationInterceptor(authenticator: SharedStoreAuthenticator(store: store, server: server))
    let sessionB = AuthenticationInterceptor(authenticator: SharedStoreAuthenticator(store: store, server: server))
    let session = NetworkSession(baseUrl: "https://example.invalid")

    var requestA = URLRequest(url: endpoint)
    var requestB = URLRequest(url: endpoint)
    try await sessionA.adapt(urlRequest: &requestA)
    try await sessionB.adapt(urlRequest: &requestB)

    // Both requests now carry token-0, as two devices holding the same synced credential would.
    await store.arm(requiredReads: 2)

    let unauthorized = makeUnauthorizedError()
    let pinnedA = requestA
    let pinnedB = requestB

    async let retriedA: Void = {
        var request = pinnedA
        _ = try? await sessionA.retry(urlRequest: &request, for: session, dueTo: unauthorized)
    }()

    async let retriedB: Void = {
        var request = pinnedB
        _ = try? await sessionB.retry(urlRequest: &request, for: session, dueTo: unauthorized)
    }()

    _ = await (retriedA, retriedB)

    // The rotation that succeeded issued `token-1`; the loser replayed `token-0` and failed.
    // The shared cell must hold the winner's credential, not be emptied by the loser.
    let surviving = await store.current
    #expect(surviving == TestCredential(accessToken: "token-1"))
}
