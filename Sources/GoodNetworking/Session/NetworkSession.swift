//
//  NetworkSession.swift
//  GoodNetworking
//
//  Created by Dominik Pethö on 8/17/20.
//

import Alamofire
import Foundation

/// Executes network requests for the client app.
public class NetworkSession {

    // MARK: - Static

    public static var `default` = NetworkSession()

    // MARK: - Private

    private let session: Alamofire.Session
    private let configuration: NetworkSessionConfiguration?

    private let baseUrl: String?

    // MARK: - Initialization

    /// A public initializer that sets the baseURL and configuration properties, and initializes the underlying `Session` object.
    public init(
        baseUrl: String? = nil,
        configuration: NetworkSessionConfiguration = .default
    ) {
        self.baseUrl = baseUrl
        self.configuration = configuration

        session = .init(
            configuration: configuration.urlSessionConfiguration,
            interceptor: configuration.interceptor,
            serverTrustManager: configuration.serverTrustManager,
            eventMonitors: configuration.eventMonitors
        )
    }

}

// MARK: - Request

public extension NetworkSession {

    /// Builds a DataRequest object by constructing URL and Body parameters.
    ///
    /// - Parameters:
    ///   - endpoint: A GREndpoint instance representing the endpoint.
    ///   - base: An optional BaseURL instance representing the base URL. If not provided, the default `baseUrl` property will be used.
    /// - Returns: A DataRequest object that is ready to be executed.
    func request(endpoint: Endpoint, base: String? = nil) -> DataRequest {
        let baseUrl = base ?? baseUrl ?? ""

        return session.request(
            try? endpoint.url(on: baseUrl),
            method: endpoint.method,
            parameters: endpoint.parameters?.dictionary,
            encoding: endpoint.encoding,
            headers: endpoint.headers
        )
    }

}

// MARK: - Download

public extension NetworkSession {

    /// Creates a download request for the given `endpoint`.
    ///
    /// - Parameters:
    ///   - endpoint: The endpoint to make the request to.
    ///   - base: The base URL to use for the request. Defaults to nil.
    ///   - customFileName: The custom file name for the downloaded file.
    /// - Returns: A download request for the given endpoint.
    func download(endpoint: Endpoint, base: String? = nil, customFileName: String) -> DownloadRequest {
        let baseUrl = base ?? baseUrl ?? ""

        let destination: DownloadRequest.Destination = { temporaryURL, _ in
            let directoryURLs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            let url = directoryURLs.first?.appendingPathComponent(customFileName) ?? temporaryURL

            return (url, [.removePreviousFile, .createIntermediateDirectories])
        }

        return session.download(
            try? endpoint.url(on: baseUrl),
            method: endpoint.method,
            parameters: endpoint.parameters?.dictionary,
            encoding: endpoint.encoding,
            headers: endpoint.headers,
            to: destination
        )
    }

}


// MARK: - Upload

public extension NetworkSession {

    /// Uploads data to endpoint.
    ///
    /// - Parameters:
    ///   - endpoint: The endpoint manager object to specify the endpoint URL and other related information.
    ///   - data: The data to be uploaded.
    ///   - fileHeader: The header to be used for the uploaded data in the form data. Defaults to "file".
    ///   - filename: The name of the file to be uploaded.
    ///   - mimeType: The MIME type of the data to be uploaded.
    /// - Returns: The upload request object.
    func uploadWithMultipart(
        endpoint: Endpoint,
        data: Data,
        fileHeader: String = "file",
        filename: String,
        mimeType: String,
        base: String? = nil
    ) -> UploadRequest {
        let baseUrl = base ?? baseUrl ?? ""

        return session.upload(
            multipartFormData: { formData in
                formData.append(data, withName: fileHeader, fileName: filename, mimeType: mimeType)
            },
            to: try? endpoint.url(on: baseUrl),
            method: endpoint.method,
            headers: endpoint.headers
        )
    }

    /// Uploads multipart form data to endpoint.
    ///
    /// - Parameters:
    ///  - endpoint: The endpoint manager object to specify the endpoint URL and other related information.
    ///  - multipartFormData: The multipart form data to be uploaded.
    ///  - base: The base URL to use for the request. Defaults to nil.
    /// - Returns: The upload request object.
    /// ## Example
    /// ```swift
    /// let fileURL = URL(filePath: "path/to/file")
    /// let multipartFormData = MultipartFormData()
    /// multipartFormData.append(fileURL, withName: "file")
    ///
    /// let image = UIImage(named: "image")
    /// let imageData = image?.jpegData(compressionQuality: 0.5)
    /// multipartFormData.append(imageData!, withName: "image", fileName: "image.jpg", mimeType: "image/jpeg")
    ///
    /// let request = session.uploadWithMultipart(endpoint: endpoint, multipartFormData: multipartFormData)
    /// ```
    func uploadWithMultipart(
        endpoint: Endpoint,
        multipartFormData: MultipartFormData,
        base: String? = nil
    ) -> UploadRequest {
        let baseUrl = base ?? baseUrl ?? ""

        return session.upload(
            multipartFormData: multipartFormData,
            to: try? endpoint.url(on: baseUrl),
            method: endpoint.method,
            headers: endpoint.headers
        )
    }

}
