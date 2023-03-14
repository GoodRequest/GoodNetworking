//
//  GRSession.swift
//
//
//  Created by Dominik Pethö on 8/17/20.
//

import Foundation
import Alamofire

/// Manages network requests for the client app. It is based on the `Session` class from the `Alamofire` library.
/// The GRSession class accepts a generic parameter T that conforms to the GREndpointManager protocol, and another generic parameter `BaseURL` that must conform to the RawRepresentable protocol, where the `RawValue` must be of type `String`.
open class GRSession<T: GREndpointManager, BaseURL: RawRepresentable> where BaseURL.RawValue == String {

    // MARK: - Private

    public let session: Session
    private let baseURL: String
    private let configuration: GRSessionConfiguration?

    // MARK: - Public

    /// A public initializer that sets the baseURL and configuration properties, and initializes the underlying `Session` object.
    public init(
        baseURL: BaseURL,
        configuration: GRSessionConfiguration = .default
    ) {
        self.baseURL = baseURL.rawValue
        self.configuration = configuration

        session = .init(
            configuration: configuration.urlSessionConfiguration,
            interceptor: configuration.interceptor,
            serverTrustManager: configuration.serverTrustManager,
            eventMonitors: configuration.eventMonitors
        )
    }

    /// Builds a DataRequest object by constructing URL and Body parameters.
    ///
    /// - Parameters:
    ///   - endpoint: A GREndpoint instance representing the endpoint.
    ///   - base: An optional BaseURL instance representing the base URL. If not provided, the default `baseURL` property will be used.
    /// - Returns: A DataRequest object that is ready to be executed.
    public func request(endpoint: T, base: BaseURL? = nil) -> DataRequest {
        let builder = endpointBuilder(endpoint: endpoint, base: base?.rawValue ?? baseURL)

        return session.request(
            builder.url ?? URL(fileURLWithPath: ""),
            method: endpoint.method,
            parameters: builder.body,
            encoding: endpoint.encoding,
            headers: endpoint.headers
        )
    }

}

// MARK: - Download

public extension GRSession {

    /// Creates a download request for the given `endpoint`.
    ///
    /// - Parameters:
    ///   - endpoint: The endpoint to make the request to.
    ///   - base: The base URL to use for the request. Defaults to nil.
    ///   - customFileName: The custom file name for the downloaded file.
    /// - Returns: A download request for the given endpoint.
    func download(endpoint: T, base: String? = nil, customFileName: String) -> DownloadRequest {
        let builder = endpointBuilder(endpoint: endpoint, base: base)

        let destination: DownloadRequest.Destination = { temporaryURL, _ in
            let directoryURLs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            let url = directoryURLs.first?.appendingPathComponent(customFileName) ?? temporaryURL

            return (url, [.removePreviousFile, .createIntermediateDirectories])
        }

        return session.download(
            builder.url ?? URL(fileURLWithPath: ""),
            method: endpoint.method,
            parameters: builder.body,
            encoding: endpoint.encoding,
            headers: endpoint.headers,
            to: destination
        )
    }

}


// MARK: - Upload

public extension GRSession {

    /// A function to upload data to a given endpoint using the multipart form data format.
    ///
    /// - Parameters:
    ///   - endpoint: The endpoint manager object to specify the endpoint URL and other related information.
    ///   - data: The data to be uploaded.
    ///   - fileHeader: The header to be used for the uploaded data in the form data. Defaults to "file".
    ///   - filename: The name of the file to be uploaded.
    ///   - mimeType: The MIME type of the data to be uploaded.
    /// - Returns: The upload request object.
    func uploadWithMultipart(
        endpoint: GREndpointManager,
        data: Data,
        fileHeader: String = "file",
        filename: String,
        mimeType: String
    ) -> UploadRequest {
        return session.upload(
            multipartFormData: {formData in
                formData.append(data, withName: fileHeader, fileName: filename, mimeType: mimeType)
            },
            to: EndpointConvertible(endpoint: endpoint, baseURL: baseURL),
            method: endpoint.method,
            headers: endpoint.headers
        )
    }

}

/// Represents a URL endpoint that is a combination of a base URL and an endpoint conforming to GREndpointManager protocol.
/// The class implements the URLConvertible protocol, which allows the resulting endpoint URL to be converted to a URL instance.
public class EndpointConvertible: URLConvertible {

    let baseURL: String
    let endpoint: GREndpointManager

    init(endpoint: GREndpointManager, baseURL: String) {
        self.baseURL = baseURL
        self.endpoint = endpoint
    }

    /// Creates a URL from the baseURL and endpoint path.
    ///
    /// - Throws: An error if the baseURL can't be converted to a URL object.
    /// - Returns: Returns a URL object created from the baseURL and endpoint path.
    public func asURL() throws -> URL {
        var url = try baseURL.asURL()
        url.appendPathComponent(endpoint.path)
        return url
    }

}

// MARK: - Request Builder

private extension GRSession {

    /// Endpoint builder function that creates a URL and a dictionary of body parameters for an API call.
    /// 
    /// - Parameters:
    ///   - endpoint: The endpoint to be built.
    ///   - base: Optional base URL string to use instead of the default base URL. Defaul is `nil`
    /// - Returns: A tuple containing the created URL and a dictionary of body parameters.
    func endpointBuilder(endpoint: T, base: String? = nil) -> (url: URL?, body: [String: Any]?) {
        let path: URL? = try? endpoint.asURL(baseURL: base ?? baseURL)
        var bodyData: [String: Any]?

        switch endpoint.parameters {
        case .parameters(let params)?:
            bodyData = params

        case .model(let encodable)?:
            if let jsonDictionary = (encodable as? Encodable & WithCustomEncoder)?.jsonDictionary {
                bodyData = jsonDictionary
            } else {
                let encoder = JSONEncoder()
                
                guard let data = try? encoder.encode(encodable) else { return (path, nil) }

                bodyData = (try? JSONSerialization.jsonObject(with: data, options: .allowFragments))
                    .flatMap { $0 as? [String: Any] }
            }

        default:
            break
        }

        return (path, bodyData)
    }

}
