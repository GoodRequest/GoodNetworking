import XCTest
import GoodNetworking
import Alamofire
import Combine

enum TestEndpoint: Endpoint {

    case unkeyedTopLevelList(MyStruct)

    var path: String {
        switch self {
        case .unkeyedTopLevelList:
            return "post"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .unkeyedTopLevelList:
            return .post
        }
    }

    var parameters: EndpointParameters? {
        switch self {
        case .unkeyedTopLevelList(let request):
            return .parameters(request.objects.map { $0.jsonDict() as? [String: any Sendable]}.asParameters())
        }
    }

    var headers: HTTPHeaders? {
        return [
            .defaultAcceptEncoding,
            .defaultAcceptLanguage,
            .defaultUserAgent
        ]
    }

    var encoding: ParameterEncoding {
        switch self {
        case .unkeyedTopLevelList:
            return ArrayEncoding(defaultEncoder: JSONEncoding.default)
        }
    }

    func url(on baseUrl: String) throws -> URL {
        var url = try baseUrl.asURL()
        url.appendPathComponent(path)
        return url
    }

}
