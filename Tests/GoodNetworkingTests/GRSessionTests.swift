import XCTest
import GoodNetworking
import Alamofire

class Endpoint: GREndpointManager {

    init() {}

    var path: String = ""

    var method: HTTPMethod {
        return HTTPMethod.post
    }

    var queryParameters: EndpointParameters? {
        return nil
    }

    var parameters: EndpointParameters? {
        return nil
    }

    var headers: HTTPHeaders? {
        return nil
    }

    var encoding: ParameterEncoding {
        return URLEncoding.default
    }

    func asURL(baseURL: String) throws -> URL {
        return URL(string: "feafa")!
    }

}

final class GRSessionTests: XCTestCase {

    enum Base: String {

        case base = "https://"

    }

    func testGRSession() {
        let session = GRSession<Endpoint, Base>(baseURL: .base, configuration: .default)
        XCTAssert(true)
    }

}
