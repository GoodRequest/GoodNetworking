//
//  DefaultBaseUrlProvider.swift
//  GoodNetworking
//
//  Created by Andrej Jasso on 15/10/2024.
//

/// A simple URL provider that returns a predefined base URL.
///
/// `DefaultBaseUrlProvider` conforms to `BaseUrlProviding` and is used to provide a static base URL for network requests.
/// This struct is initialized with a given base URL, and it returns that URL when resolved asynchronously.
///
/// Example usage:
/// ```
/// let urlProvider = DefaultBaseUrlProvider(baseUrl: "https://api.example.com")
/// let resolvedUrl = await urlProvider.resolveBaseUrl()
/// ```
///
/// - Note: The base URL is provided at initialization and remains constant.
public struct DefaultBaseUrlProvider: BaseUrlProviding {

    /// The base URL string to be used for network requests.
    let baseUrl: String

    /// Initializes the provider with a given base URL.
    ///
    /// - Parameter baseUrl: The base URL that will be returned when resolving the URL.
    init(baseUrl: String) {
        self.baseUrl = baseUrl
    }

    /// Resolves and returns the predefined base URL asynchronously.
    ///
    /// This method returns the base URL that was passed during initialization.
    ///
    /// - Returns: The base URL as a `String?`.
    public func resolveBaseUrl() async -> String? {
        return baseUrl
    }

}
