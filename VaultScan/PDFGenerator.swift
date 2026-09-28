import SwiftUI

// @MainActor ensures the UI rendering happens safely on the main thread
@MainActor
class PDFGenerator {
    
    static func generatePDF(from items: [VaultItem]) -> URL? {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("VaultScan_Expense_Report.pdf")
        
        let total = items.reduce(0) { $0 + $1.amount }
        
        // 1. We design the PDF layout exactly like a normal SwiftUI View!
        let reportView = VStack(alignment: .leading, spacing: 16) {
            Text("VaultScan Expense Report")
                .font(.system(size: 32, weight: .bold))
            
            Text("Generated on: \(Date(), format: .dateTime.month().day().year())")
                .foregroundColor(.gray)
            
            Divider()
            
            // Table Header
            HStack {
                Text("Date").bold().frame(width: 100, alignment: .leading)
                Text("Vendor").bold().frame(maxWidth: .infinity, alignment: .leading)
                Text("Category").bold().frame(width: 100, alignment: .leading)
                Text("Amount").bold().frame(width: 80, alignment: .trailing)
            }
            
            Divider()
            
            // Table Rows
            ForEach(items) { item in
                HStack {
                    Text(item.date, format: .dateTime.month().day().year())
                        .frame(width: 100, alignment: .leading)
                    
                    Text(item.vendorName)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text(item.category)
                        .frame(width: 100, alignment: .leading)
                    
                    Text(String(format: "$%.2f", item.amount))
                        .frame(width: 80, alignment: .trailing)
                }
                .font(.system(size: 14))
                Divider()
            }
            
            Spacer()
            
            // Grand Total
            HStack {
                Spacer()
                Text("Total:")
                    .font(.title2)
                Text(String(format: "$%.2f", total))
                    .font(.title2.bold())
            }
        }
        .padding(40)
        .frame(width: 612, height: 792) // Standard 8.5 x 11 inch paper size
        .background(Color.white)
        
        // 2. We tell SwiftUI to render that view into a PDF document
        let renderer = ImageRenderer(content: reportView)
        
        renderer.render { size, context in
            var box = CGRect(x: 0, y: 0, width: size.width, height: size.height)
            guard let pdf = CGContext(tempURL as CFURL, mediaBox: &box, nil) else { return }
            
            pdf.beginPDFPage(nil)
            context(pdf)
            pdf.endPDFPage()
            pdf.closePDF()
        }
        
        return tempURL
    }
}
