import Foundation
import Combine

enum MessageUserType {
    case user
    case assistant
}

class OpenAIConnector: ObservableObject {
    let openAIURL = URL(string: "https://api.openai.com/v1/chat/completions")
    // TODO: Retrieve the key securely
    let openAIKey = "ADD OPEN AI KEY" // Replace with your method to retrieve the key securely
    
    @Published var messageLog: [[String: String]] = [
        ["role": "system", "content": "AI Powered Football Insights."]
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
    
    func test() {
        let hardcodedQuery = """
        SELECT
            player_name,
            position,
            recent_team,
            round(sum(receiving_yards), 2) AS "Rec Yds",
            round(avg(receiving_yards), 2) AS "Avg Rec Yds",
            round(sum(receiving_tds), 2) AS "Rec TDs",
            round(avg(receiving_tds), 2) AS "Avg Rec TDs"
        FROM
            weekly_data
        WHERE
            position = 'WR' AND season = 2023
        GROUP BY
            player_name
        ORDER BY
            sum(receiving_yards) DESC;
        """

        if let queryResult = DatabaseManager.shared.executeQuery(query: hardcodedQuery) {
            // Ensure name, position, recent team are always first
            var columnTitles = Array(queryResult[0].keys)
            columnTitles.removeAll { $0 == "player_name" || $0 == "recent_team" || $0 == "position" }
            columnTitles.insert("position", at: 0)
            columnTitles.insert("recent_team", at: 0)
            columnTitles.insert("player_name", at: 0)
            
            // Calculate the maximum length of each column
            var maxLengths: [Int] = columnTitles.map { $0.count }
            for dictionary in queryResult {
                for (index, title) in columnTitles.enumerated() {
                    let valueString = "\(dictionary[title] ?? "")"
                    maxLengths[index] = max(maxLengths[index], valueString.count)
                }
            }
            
            // Create a header row with column names
            let headerRow = columnTitles.enumerated().map { (index, title) in
                return title.padding(toLength: maxLengths[index], withPad: " ", startingAt: 0)
            }.joined(separator: "\t")
            
            // Create the data rows
            let queryResultString = queryResult.compactMap { dictionary in
                columnTitles.enumerated().compactMap { (index, title) in
                    if let valueString = dictionary[title] as? String, let value = Double(valueString) {
                        return String(format: "%.3f", value).padding(toLength: maxLengths[index], withPad: " ", startingAt: 0)
                    } else {
                        return "\(dictionary[title] ?? "")".padding(toLength: maxLengths[index], withPad: " ", startingAt: 0)
                    }
                }.joined(separator: "\t")
            }.joined(separator: "\n")
            
            // Combine header and data rows and log the message
            let tableString = headerRow + "\n" + queryResultString
            logMessage(tableString, messageUserType: .assistant)
        } else {
            logMessage("Error executing query", messageUserType: .assistant)
        }
    }
    
    
    func sendToAssistant(userQuestion: String) {
        logMessage(userQuestion, messageUserType: .user)
        
        var request = URLRequest(url: self.openAIURL!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(self.openAIKey)", forHTTPHeaderField: "Authorization")
        
        let prompt = """
        given these column names from table weekly_data: player_id    player_name    position    position_group    headshot_url    recent_team    season    week    season_type    completions    attempts    passing_yards    passing_tds    interceptions    sacks    sack_yards    sack_fumbles    sack_fumbles_lost    passing_air_yards    passing_yards_after_catch    passing_first_downs    passing_epa    passing_2pt_conversions    pacr    dakota    carries    rushing_yards    rushing_tds    rushing_fumbles    rushing_fumbles_lost    rushing_first_downs    rushing_epa    rushing_2pt_conversions    receptions    targets    receiving_yards    receiving_tds    receiving_fumbles    receiving_fumbles_lost    receiving_air_yards    receiving_yards_after_catch    receiving_first_downs    receiving_epa    receiving_2pt_conversions    racr    target_share    air_yards_share    wopr    special_teams_tds    fantasy_points    fantasy_points_ppr    opponent_team ...Here is an example row: 00-0035676    A.J. Brown    WR    WR    https://static.www.nfl.com/image/private/f_auto,q_auto/league/a014sgzctarbvhwb35lw    PHI    2023    1    REG    0    0    0.0    0    0.0    0.0    0.0    0    0    0.0    0.0    0.0        0            0    0.0    0    0.0    0.0    0.0        0    7    10    79.0    0    0.0    0.0    171.0    13.0    4.0    1.2331640720367400    0    0.46198830008506800    0.3333333432674410    0.5876288414001470    0.9113401770591740    0.0    7.900000095367430    14.899999618530300    NE...write a sql lite query that answers this question: \(userQuestion)...Use all columns relevant to player's position to write the query. Show only the query and no other comments you have about it. Consider that each row consists of ONLY WEEKLY player stats, therefore group by player_name and calculate the SUM and AVG...then make sure to round the sum and avg to 2 decimal places. Always rename column names, EXCLUDING player_name, recent_team, and position, to start with a capital letter, be surrounded by quotes (in the sql query) if the new name has multiple words (has a space), and be simple (don't include any underscores... examples include passing_yards to Pass Yds average pass yards to Avg Pass Yds, receiving_yards to Rec Yds, etc...).  Ensure you are returning just the query, with no extra characters (such as newline). Do not set a limit. ALWAYS display the players name, then position, then recent team first, and then the remaining relevant columns to the users question.
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
            print("OpenAI API Response: \(jsonStr)")
            
            let responseHandler = OpenAIResponseHandler()
            let assistantResponse = responseHandler.decodeJson(jsonString: jsonStr)?.choices[0].message["content"] ?? "error"
            
            // Replace newline characters in the assistantResponse
            let cleanedAssistantResponse = assistantResponse.replacingOccurrences(of: "\n", with: " ")
            
            print("DEBUG: Cleaned Response: \(cleanedAssistantResponse)")
            
            if let queryResult = DatabaseManager.shared.executeQuery(query: cleanedAssistantResponse) {
                // Ensure name, position, recent team are always first
                var columnTitles = Array(queryResult[0].keys)
                columnTitles.removeAll { $0 == "player_name" || $0 == "recent_team" || $0 == "position" }
                columnTitles.insert("position", at: 0)
                columnTitles.insert("recent_team", at: 0)
                columnTitles.insert("player_name", at: 0)
                
                // Calculate the maximum length of each column
                var maxLengths: [Int] = columnTitles.map { $0.count }
                for dictionary in queryResult {
                    for (index, title) in columnTitles.enumerated() {
                        let valueString = "\(dictionary[title] ?? "")"
                        maxLengths[index] = max(maxLengths[index], valueString.count)
                    }
                }
                
                // Create a header row with column names
                let headerRow = columnTitles.enumerated().map { (index, title) in
                    return title.padding(toLength: maxLengths[index], withPad: " ", startingAt: 0)
                }.joined(separator: "\t")
                
                // Create the data rows
                let queryResultString = queryResult.compactMap { dictionary in
                    columnTitles.enumerated().compactMap { (index, title) in
                        if let valueString = dictionary[title] as? String, let value = Double(valueString) {
                            return String(format: "%.3f", value).padding(toLength: maxLengths[index], withPad: " ", startingAt: 0)
                        } else {
                            return "\(dictionary[title] ?? "")".padding(toLength: maxLengths[index], withPad: " ", startingAt: 0)
                        }
                    }.joined(separator: "\t")
                }.joined(separator: "\n")
                
                // Combine header and data rows and log the message
                let tableString = headerRow + "\n" + queryResultString
                logMessage(tableString, messageUserType: .assistant)
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
