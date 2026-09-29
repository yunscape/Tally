import Foundation

class ReportGenerator {
    static func generateCSV(from items: [VaultItem]) -> URL? {
        var csvString = "Date,Vendor,Category,Amount,Warranty Expiry\n"

        let formatter = DateFormatter()
        formatter.dateStyle = .short

        for item in items {
            let dateStr = formatter.string(from: item.date)

            let safeVendor = item.vendorName.replacingOccurrences(of: ",", with: "")
            
            let amountStr = String(format: "%.2f", item.amount)
            
            var expiryStr = "N/A"
            if item.isWarrantyTracked, let expiry = item.expiryDate {
                expiryStr = formatter.string(from: expiry)
            }

            let clusterName = item.cluster?.name ?? "Miscellaneous"
            let safeCluster = clusterName.replacingOccurrences(of: ",", with: "")

            let row = "\(dateStr),\(safeVendor),\(safeCluster),\(amountStr),\(expiryStr)\n"
            csvString.append(row)
        }
        let fileName = "VaultScan_Report.csv"
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileURL = tempDirectory.appendingPathComponent(fileName)
        
        do {
            try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("Failed to create CSV file: \(error)")
            return nil
        }
    }
}
