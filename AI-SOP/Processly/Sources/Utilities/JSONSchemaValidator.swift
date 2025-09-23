import Foundation

struct JSONSchemaValidator {
    func validate(_ data: Data) throws {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw ValidationError.invalidStructure
        }
        let requiredKeys = ["title", "summary", "tools_needed", "steps", "warnings", "tags"]
        for key in requiredKeys where json[key] == nil {
            throw ValidationError.missingKey(key)
        }
        guard let title = json["title"] as? String, title.count <= 60 else {
            throw ValidationError.invalidTitle
        }
        guard let steps = json["steps"] as? [[String: Any]], steps.count <= 15 else {
            throw ValidationError.invalidSteps
        }
        for step in steps {
            guard step["number"] != nil, step["instruction"] is String else {
                throw ValidationError.invalidSteps
            }
        }
    }

    enum ValidationError: Error {
        case invalidStructure
        case missingKey(String)
        case invalidTitle
        case invalidSteps
    }
}
