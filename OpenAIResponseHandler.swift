//
//  OpenAIResponseHandler.swift
//  GridIronGPT
//
//  Created by Alex Zaharia on 8/24/23.
//

import Foundation

struct OpenAIResponseHandler {
    func decodeJson(jsonString: String) -> OpenAIResponse? {
        let json = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()
        do {
            let product = try decoder.decode(OpenAIResponse.self, from: json)
            return product
        } catch let DecodingError.dataCorrupted(context) {
            print("Data corrupted: \(context)")
        } catch let DecodingError.keyNotFound(key, context) {
            print("Key '\(key)' not found: \(context.debugDescription)")
        } catch let DecodingError.typeMismatch(type, context) {
            print("Type '\(type)' mismatch: \(context.debugDescription)")
        } catch let DecodingError.valueNotFound(value, context) {
            print("Value '\(value)' not found: \(context.debugDescription)")
        } catch {
            print("Error decoding OpenAI API Response: \(error.localizedDescription)")
        }
        return nil
    }
}

struct OpenAIResponse: Codable {
    var id: String
    var object: String
    var created: Int
    var model: String
    var choices: [Choice]
    var usage: Usage
}

struct Choice: Codable {
    var index: Int
    var message: [String: String]
    var finish_reason: String
}


struct Usage: Codable {
    var prompt_tokens: Int
    var completion_tokens: Int
    var total_tokens: Int
}

//{
//  "id": "chatcmpl-123",
//  "object": "chat.completion",
//  "created": 1677652288,
//  "choices": [{
//    "index": 0,
//    "message": {
//      "role": "assistant",
//      "content": "\n\nHello there, how may I assist you today?",
//    },
//    "finish_reason": "stop"
//  }],
//  "usage": {
//    "prompt_tokens": 9,
//    "completion_tokens": 12,
//    "total_tokens": 21
//  }
//}
