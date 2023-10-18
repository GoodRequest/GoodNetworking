import XCTest
import GoodNetworking
import Alamofire
import Combine

enum Endpoint: GREndpointManager {
    
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
            return .parameters(request.objects.map { $0.jsonDict() }.asParameters())
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

    func asURL(baseURL: String) throws -> URL {
        var url = try baseURL.asURL()
        url.appendPathComponent(path)
        return url
    }

}
