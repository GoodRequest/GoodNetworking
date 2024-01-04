![Logo](good-networking.png)

# GoodNetworking

[![iOS Version](https://img.shields.io/badge/iOS_Version->=_13.0-brightgreen?logo=apple&logoColor=green)]() 
[![Swift Version](https://img.shields.io/badge/Swift_Version-5.9-green?logo=swift)](https://docs.swift.org/swift-book/)
[![Supported devices](https://img.shields.io/badge/Supported_Devices-iPhone/iPad-green)]()
[![Contains Test](https://img.shields.io/badge/Tests-YES-blue)]()
[![Dependency Manager](https://img.shields.io/badge/Dependency_Manager-SPM-red)](#swiftpackagemanager)

Handles Swift HTTP networking with the use of various tools such as `GRSession`, as well as extensions of `Encodable` and `DataRequest`. 
The GRSession provides a powerful and flexible mechanism for managing HTTP sessions, enabling developers to easily handle complex network interactions. 
Extensions of Encodable and DataRequest provide added functionality for encoding and decoding data, 
making it easier to handle data transfer between the application and remote servers. 

## Documentation
Check out GoodNetworking documentation [here](https://goodrequest.github.io/GoodNetworking/documentation/goodnetworking/)

## Installation
### Swift Package Manager

Create a `Package.swift` file and add the package dependency into the dependencies list.
Or to integrate without package.swift add it through the Xcode add package interface.

[//]: <> (Don't forget add the version once available.')
```swift
import PackageDescription

let package = Package(
    name: "SampleProject",
    dependencies: [
        .package(url: "https://github.com/GoodRequest/GoodNetworking" from: "addVersion")
    ]
)
```

## Usage

Define two enums: 
- one for the base API address called `ApiServer`
- one that follows the `Endpoint` protocol, more information [here](https://goodrequest.github.io/GoodNetworking/documentation/goodnetworking/models/endpoint/)

Create a RequestManager using `GRSession`

```swift
import GoodNetworking
import Combine

enum ApiServer: String {

    case baseURL = "https://api.users.com"

}

enum RequestEndpoint: GREndpointManager {

    // MARK: - User Profile
    
    case userProfile
    
    var path: String { "/user/details/profile" }
    
    var method: HTTPMethod { .get }
    
    var parameters: EndpointParameters? { nil }
    
    var headers: HTTPHeaders? { nil }
    
    var encoding: ParameterEncoding { JSONEncoding.default }

    func asURL(baseURL: String) throws -> URL {
        var url = try baseURL.asURL()
        url.appendPathComponent(path)
        return url
    }

}


class UserRequestManager: UserRequestManagerType {

    // MARK: - Constants

    internal let session: GRSession<RequestEndpoint, ApiServer>

    // MARK: - Initialization

    init(baseURL: String) {
        session = GRSession(
            configuration: .default,
            baseURL: baseURL
        )
    }

    // MARK: - User Profile

    func fetchUserProfile() -> AnyPublisher<ProfileResponse, AFError> {
        return session.request(endpoint: .userProfile)
            .validateToCustomError()
            .goodify()
    }

}
```
Then inside your viewModel just call
```swift
fetchUserProfile()
```
The result is a publisher so you can continue chaining Combine functions.

## License
GoodNetworking is released under the MIT license. See [LICENSE](LICENSE.md) for details.
