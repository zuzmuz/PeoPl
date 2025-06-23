enum LSP {

    // swiftlint:disable:next type_name
    enum Id: Codable {
        case int(Int)
        case string(String)

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let int = try? container.decode(Int.self) {
                self = .int(int)
            } else if let string = try? container.decode(String.self) {
                self = .string(string)
            } else {
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "ID must be either Int or String")
            }
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case let .int(int):
                try container.encode(int)
            case let .string(string):
                try container.encode(string)
            }
        }
    }

    enum Method: String, Codable {
    }

    enum Params: Codable {
    }

    struct RequestMessage {
        let jsonrpc: String
        let id: Id
        let method: Method
        let params: Params?
    }

    struct NotificationMessage {
        let jsonrpc: String
        let method: Method
        let params: Params
    }

    struct ResponseMessage: Codable {
        let jsonrpc: String
        let id: Id?
        let result: Result<ResponseResult, ResponseError>
    }

    enum ResponseResult: Codable {
    }

    enum ResponseError: Codable, Error {
    }

}
