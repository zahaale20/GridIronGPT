import Foundation
import SQLite

class DatabaseManager {
    static let shared = DatabaseManager()
    
    private(set) lazy var db: Connection? = {
        do {
            let dbPath = Bundle.main.path(forResource: "GridIron", ofType: "db")!
            return try Connection(dbPath, readonly: true)
        } catch {
            print("Database connection failed: \(error)")
            return nil
        }
    }()
    
    private init() {}
    
    func executeQuery(query: String) -> [Row]? {
        guard let db = db else {
            print("Database not initialized.")
            return nil
        }

        do {
            var result: [Row] = []
            for row in try db.prepare(query) {
                result.append(row)
            }
            return result
        } catch {
            print("Error executing query: \(error)")
            return nil
        }
    }
}
