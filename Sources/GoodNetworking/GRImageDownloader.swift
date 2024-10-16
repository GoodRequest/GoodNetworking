//
//  GRImageDownloader.swift
//  GoodNetworking
//
//  Created by Andrej Jasso on 24/05/2022.
//

import Foundation
import AlamofireImage
import Alamofire

/// The GRImageDownloader class provides a setup method for configuring and creating an instance of an ImageDownloader.
public actor GRImageDownloader {

    /// The GRImageDownloaderConfiguration holds a single variable maxActiveDownloads, which represents the maximum number of concurrent downloads.
    public struct GRImageDownloaderConfiguration {

        let maxActiveDownloads: Int

    }

    // MARK: - Constants

    enum C {

        static let imageDownloaderDispatchQueueKey = "ImageDownloaderDispatchQueue"
        static let imageDownloaderOperationQueueKey = "ImageDownloaderOperationQueue"

    }

    // MARK: - Variables

    static var shared: ImageDownloader?

    // MARK: - Public

    /// Sets up an authorized image downloader with the given session configuration and downloader configuration.
    /// 
    /// - Parameters:
    ///   - sessionConfiguration: The GRSessionConfiguration used to create the URLSession and Session. (default: .default)
    ///   - downloaderConfiguration: The GRImageDownloaderConfiguration used to set the max concurrent operation count and max active downloads.
    static func setupAuthorizedImageDownloader(
        sessionConfiguration: NetworkSessionConfiguration = .default,
        downloaderConfiguration: GRImageDownloaderConfiguration
    ) {
        let imageDownloaderQueue = DispatchQueue(label: C.imageDownloaderDispatchQueueKey)
        let operationQueue = OperationQueue()

        operationQueue.name = C.imageDownloaderOperationQueueKey
        operationQueue.underlyingQueue = imageDownloaderQueue
        operationQueue.maxConcurrentOperationCount = downloaderConfiguration.maxActiveDownloads
        operationQueue.qualityOfService = .default


        let sessionDelegate = SessionDelegate()

        let urlSession = URLSession(
            configuration: sessionConfiguration.urlSessionConfiguration,
            delegate: sessionDelegate,
            delegateQueue: operationQueue
        )

        let session = Session(
            session: urlSession,
            delegate: sessionDelegate,
            rootQueue: imageDownloaderQueue,
            interceptor: sessionConfiguration.interceptor,
            serverTrustManager: sessionConfiguration.serverTrustManager,
            eventMonitors: sessionConfiguration.eventMonitors
        )

        shared = ImageDownloader(
            session: session,
            downloadPrioritization: .fifo,
            maximumActiveDownloads: downloaderConfiguration.maxActiveDownloads,
            imageCache: AutoPurgingImageCache()
        )
    }

}
