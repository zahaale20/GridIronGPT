import Foundation
import Combine

enum MessageUserType {
    case user
    case assistant
}

class OpenAIConnector: ObservableObject {
    let openAIURL = URL(string: "https://api.openai.com/v1/chat/completions")
    let openAIKey = "INSERT API KEY HERE"

    @Published var messageLog: [[String: String]] = [
        ["role": "system", "content": "Grid Iron GPT"]
    ]
    
    func logMessage(_ message: String, messageUserType: MessageUserType) {
        var messageUserTypeString = ""
        switch messageUserType {
        case .user:
            messageUserTypeString = "user"
        case .assistant:
            messageUserTypeString = "assistant"
        }
        
        messageLog.append(["role": messageUserTypeString, "content": message])
    }
    
    private func executeRequest(request: URLRequest, withSessionConfig sessionConfig: URLSessionConfiguration?) -> (data: Data?, error: Error?) {
        let semaphore = DispatchSemaphore(value: 0)
        let session: URLSession
        if let config = sessionConfig {
            session = URLSession(configuration: config)
        } else {
            session = URLSession.shared
        }
        var requestData: Data?
        var requestError: Error?
        let task = session.dataTask(with: request as URLRequest, completionHandler:{ (data: Data?, response: URLResponse?, error: Error?) -> Void in
            requestData = data
            requestError = error
            semaphore.signal()
        })
        task.resume()

        let timeout = DispatchTime.now() + .seconds(20)
        _ = semaphore.wait(timeout: timeout)
        return (data: requestData, error: requestError)
    }

    func sendToAssistant(userQuestion: String) {
        var request = URLRequest(url: self.openAIURL!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(self.openAIKey)", forHTTPHeaderField: "Authorization")
        
        let prompt = """
        given these column names: name    position    recent_team    season    week    season_type    completions    attempts    passing_yards    passing_tds    interceptions    sacks    sack_yards    sack_fumbles    sack_fumbles_lost    passing_air_yards    passing_yards_after_catch    passing_first_downs    passing_2pt_conversions    carries    rushing_yards    rushing_tds    rushing_fumbles    rushing_fumbles_lost    rushing_first_downs    rushing_2pt_conversions    receptions    targets    receiving_yards    receiving_tds    receiving_fumbles    receiving_fumbles_lost    receiving_air_yards    receiving_yards_after_catch    receiving_first_downs    receiving_2pt_conversions    target_share    air_yards_share    fantasy_points    fantasy_points_ppr    total_yards    ypa    ypc    ypr    touches    count    comp_percentage    pass_td_percentage    int_percentage    rush_td_percentage    rec_td_percentage    total_tds    td_percentage    pr    ht    wt... from a table called player_stats ...Here is two example rows: Aaron Rodgers    QB    GB    2008    17    REG    21    31    308    3    0    4    35    1    0    326    109    11    0    1    -1    0    0    0    0    0    0    0    0    0    0    0    0    0    0    0    0    24.22    24.22    307    9.94    -1    0    32    1    0.677    0.097    0    0    0    3    0.094    126.54    6-2    223...write a sql lite query that answers this question: \(userQuestion)...Use only relevant columns to write the query. Set the limit of players showing to 5. Show only the query and no other comments you have about it. Select only player name to display unless asked differently. Consider that each row consists of ONLY WEEKLY player stats, so take the aggregate average of the statistics unless asked otherwise. Exclude players who have only a few games played unless asked otherwise.
        """
            
        let httpBody: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": [
                ["role": "system", "content": prompt]
            ]
        ]

        var httpBodyJson: Data? = nil

        do {
            httpBodyJson = try JSONSerialization.data(withJSONObject: httpBody, options: .prettyPrinted)
        } catch {
            print("Unable to convert to JSON \(error)")
        }
        
        request.httpBody = httpBodyJson
        
        let result = executeRequest(request: request, withSessionConfig: nil)
        let requestData = result.data
        let requestError = result.error
        
        if let error = requestError {
            print("API Request Error: \(error.localizedDescription)")
            logMessage("error", messageUserType: .assistant)
            return
        }

        if let data = requestData {
            var jsonStr = String(data: data, encoding: .utf8) ?? ""
            
            jsonStr = jsonStr.replacingOccurrences(of: "\n", with: "")
            
            let responseHandler = OpenAIResponseHandler()
            let assistantResponse = responseHandler.decodeJson(jsonString: jsonStr)?.choices[0].message["content"] ?? "error"
            logMessage(assistantResponse, messageUserType: .assistant)

            if let queryResult = DatabaseManager.shared.executeQuery(query: assistantResponse) {
                let queryResultString = queryResult.map { "\($0)" }.joined(separator: "\n")
                logMessage(queryResultString, messageUserType: .assistant)
            } else {
                logMessage("Error executing query", messageUserType: .assistant)
            }
        }
    }
}

extension Dictionary: Identifiable {
    public var id: UUID {
        UUID()
    }
}

extension Array: Identifiable {
    public var id: UUID {
        UUID()
    }
}

extension String: Identifiable {
    public var id: UUID {
        UUID()
    }
}
