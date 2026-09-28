import Foundation

class ReportGenerator {
    
    // Converts your Vault items into a temporary CSV file
    static func generateCSV(from items: [VaultItem]) -> URL? {
        // 1. Create the spreadsheet headers
        var csvString = "Date,Vendor,Category,Amount,Warranty Expiry\n"
        
        // 2. Format the date to be easily readable
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        
        // 3. Loop through every item in your database
        for item in items {
            let dateStr = formatter.string(from: item.date)
            
            // Remove any commas from vendor names so it doesn't break the CSV format
            let safeVendor = item.vendorName.replacingOccurrences(of: ",", with: "")
            
            let amountStr = String(format: "%.2f", item.amount)
            
            var expiryStr = "N/A"
            if item.isWarrantyTracked, let expiry = item.expiryDate {
                expiryStr = formatter.string(from: expiry)
            }
            
            // --- UPDATED: Safely grab the cluster name and ensure it doesn't break CSV formatting ---
            let clusterName = item.cluster?.name ?? "Miscellaneous"
            let safeCluster = clusterName.replacingOccurrences(of: ",", with: "")
            
            // 4. Create the row
            let row = "\(dateStr),\(safeVendor),\(safeCluster),\(amountStr),\(expiryStr)\n"
            csvString.append(row)
        }
        
        // 5. Save the file temporarily on the device so the Share Sheet can grab it
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
