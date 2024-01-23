import SwiftUI

struct MessageView: View {
    @State private var count = 0
    
    var message: [String: String]
    
    var messageColor: Color {
        if message["role"] == "user" {
            return Color(red: 170/255, green: 170/255, blue: 170/255)
        } else if message["role"] == "assistant" {
            return Color(red: 77/255, green: 166/255, blue: 255/255)
        } else {
            return .blue
        }
    }
    
    private func abbreviateName(fullName: String) -> String {
        let components = fullName.components(separatedBy: " ")
        if components.count >= 2 {
            let firstName = components[0]
            let lastName = components.dropFirst().joined(separator: " ")
            let abbreviatedName = "\(firstName.prefix(1)). \(lastName)"
            return abbreviatedName
            // abbreviatedName now contains the first initial, period, and last name
        }
        return fullName
    }

    var columns: [[String]] {
        let rows = message["content"]?.components(separatedBy: "\n") ?? []
        guard let firstRow = rows.first else { return [] }
        let numberOfColumns = firstRow.components(separatedBy: "\t").count

        return (0..<numberOfColumns).map { columnIndex in
            rows.map { row in
                let columns = row.components(separatedBy: "\t")
                return columnIndex < columns.count ? columns[columnIndex] : ""
            }
        }
    }
    
    var firstThreeColumns: [[String]] {
        Array(columns.prefix(3))
    }

    var otherColumns: [[String]] {
        Array(columns.dropFirst(3))
    }

    
    private func debugPrint(_ index: Int, _ cell: String) -> some View {
        print("\(index): \(cell) ... index % 2 = \(index % 2) \n")
        return EmptyView() // Returns an invisible view
    }

    var body: some View {
        HStack(alignment: .top, spacing: 0) { // Explicit top alignment
            if message["role"] == "user" {
                // Display user's message
                Text(message["content"] ?? "")
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                    .foregroundColor(messageColor)
            } else if message["role"] == "assistant" {
                // Display assistant's message
                VStack(alignment: .leading, spacing: 0) {
                    Text("Player")
                        .frame(width: 128, height: 16, alignment: .leading)
                        .font(.system(size: 10))
                        .bold()
                        .background(Color.black.opacity(0.05))
                        
                    ForEach(1..<firstThreeColumns[0].count, id: \.self) { index in
                        VStack (alignment: .leading, spacing: 0) {
                            Text(abbreviateName(fullName: firstThreeColumns[0][index]))
                                .foregroundColor(.blue)
                                .frame(width: 120, height: 16, alignment: .topLeading)
                                .font(.system(size: 14))
                                .bold()
                                .padding(.init(top: 8, leading: 4, bottom: 1, trailing: 4))
                            Text(firstThreeColumns[1][index].trimmingCharacters(in: .whitespaces) + " " + firstThreeColumns[2][index].trimmingCharacters(in: .whitespaces))
                                .frame(width: 120, height: 12, alignment: .bottomLeading)
                                .font(.system(size: 10))
                                .padding(.init(top: 1, leading: 4, bottom: 8, trailing: 4))
                        }
                        .background(index % 2 == 0 ? Color.black.opacity(0.05) : Color.clear)
                    }
                }
                ScrollView(.horizontal, showsIndicators: true) {
                    HStack (spacing: 0) {
                        ForEach(0..<otherColumns.count, id: \.self) { columnIndex in
                            VStack (alignment: .center, spacing: 0) {
                                ForEach(0..<otherColumns[columnIndex].count, id: \.self) { rowIndex in
                                    let cell = otherColumns[columnIndex][rowIndex]
                                    if rowIndex == 0 {
                                        // Special handling for the first row
                                        Text(cell.trimmingCharacters(in: .whitespaces))
                                            .frame(width: 80, height: 16)
                                            .font(.system(size: 10))
                                            .bold()
                                            .background(Color.black.opacity(0.05))
                                    } else {
                                        Text(cell.trimmingCharacters(in: .whitespaces))
                                            .frame(width: 80, height: 46)
                                            .font(.system(size: 14))
                                            .background(rowIndex % 2 == 0 ? Color.black.opacity(0.05) : Color.clear)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
