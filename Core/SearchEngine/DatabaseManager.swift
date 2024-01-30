import Foundation
import SQLite

class DatabaseManager {
    static let shared = DatabaseManager()
    
    private(set) lazy var db: Connection? = {
        do {
            let dbPath = Bundle.main.path(forResource: "weekly_data", ofType: "db")!
            return try Connection(dbPath, readonly: true)
        } catch {
            print("Database connection failed: \(error)")
            return nil
        }
    }()
    
    private init() {}
    
    func executeQuery(query: String) -> [[String: Any]]? {
        guard let db = db else {
            print("Database not initialized.")
            return nil
        }

        do {
            var result: [[String: Any]] = []
            let statement = try db.prepare(query)
            for row in statement {
                var rowDict: [String: Any] = [:]
                for (index, name) in statement.columnNames.enumerated() {
                    rowDict[name] = row[index]
                }
                result.append(rowDict)
            }
            return result
        } catch {
            print("Error executing query: \(error)")
            return nil
        }
    }
}
