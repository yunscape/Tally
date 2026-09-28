import SwiftUI
import SwiftData
import Charts

struct AnalyticsView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    @Query(sort: \VaultItem.date, order: .forward) private var items: [VaultItem]
    
    @AppStorage("appTheme") private var appTheme = 0
    
    @State private var csvURL: URL?
    @State private var pdfURL: URL?
    @State private var rawSelectedDate: Date?
    
    var body: some View {
        NavigationStack {
            ZStack {
                AmbientBackground()
                
                ScrollView {
                    VStack(spacing: 24) {
                        
                        // 1. HERO METRIC
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Total Lifetime Value")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Text(String(format: "$%.2f", items.reduce(0) { $0 + $1.amount }))
                                .font(.system(size: 42, weight: .heavy, design: .rounded))
                                .monospacedDigit()
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                        
                        // 2. INTERACTIVE SWIFT CHART WITH SCRUBBER
                        VStack(alignment: .leading) {
                            Text("Category Breakdown")
                                .font(.headline)
                                .padding(.horizontal, 20)
                                .padding(.top, 20)
                            
                            Chart {
                                ForEach(chartData) { dataPoint in
                                    BarMark(
                                        x: .value("Date", dataPoint.date, unit: .day),
                                        y: .value("Amount", dataPoint.amount)
                                    )
                                    .foregroundStyle(by: .value("Category", dataPoint.category))
                                    .cornerRadius(4)
                                }
                                
                                if let selectedDate = rawSelectedDate {
                                    RuleMark(
                                        x: .value("Selected", selectedDate, unit: .day)
                                    )
                                    .foregroundStyle(Color.primary.opacity(0.2))
                                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
                                    .annotation(
                                        position: .top,
                                        spacing: 0,
                                        overflowResolution: .init(x: .fit(to: .chart), y: .disabled)
                                    ) {
                                        ScrubberAnnotationView(date: selectedDate, data: chartData)
                                    }
                                }
                            }
                            .chartXSelection(value: $rawSelectedDate)
                            .chartLegend(position: .bottom, alignment: .center, spacing: 16)
                            .frame(height: 300)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 20)
                        }
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.04), radius: 20, y: 10)
                        .padding(.horizontal, 20)
                        
                        // 3. EXPORT DATA SECTION (Preserving PDF & CSV Generator hooks)
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Export Reports")
                                .font(.headline)
                            
                            HStack(spacing: 16) {
                                if let pdfURL {
                                    ShareLink(item: pdfURL) {
                                        HStack {
                                            Label("PDF Report", systemImage: "doc.richtext.fill")
                                                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                                                .foregroundColor(.red)
                                            Spacer()
                                            Image(systemName: "square.and.arrow.up")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(Color.primary.opacity(0.04))
                                        .cornerRadius(16)
                                    }
                                    .buttonStyle(.plain)
                                }
                                
                                if let csvURL {
                                    ShareLink(item: csvURL) {
                                        HStack {
                                            Label("CSV Data", systemImage: "tablecells.fill")
                                                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                                                .foregroundColor(.green)
                                            Spacer()
                                            Image(systemName: "square.and.arrow.up")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(Color.primary.opacity(0.04))
                                        .cornerRadius(16)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(20)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.04), radius: 20, y: 10)
                        .padding(.horizontal, 20)
                        
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Analytics")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    #if os(macOS)
                    Button(action: { dismiss() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.backward")
                            Text("Back")
                        }
                    }
                    #else
                    Button("Done") { dismiss() }.fontWeight(.semibold)
                    #endif
                }
            }
            .onAppear {
                csvURL = ReportGenerator.generateCSV(from: items)
                
                Task {
                    await MainActor.run {
                        pdfURL = PDFGenerator.generatePDF(from: items)
                    }
                }
            }
            .preferredColorScheme(appTheme == 1 ? .light : appTheme == 2 ? .dark : nil)
        }
    }
    
    private var chartData: [DailyExpense] {
        var data: [DailyExpense] = []
        let calendar = Calendar.current
            
            // 1. Create a lightweight Hashable struct to replace the tuple
        struct GroupKey: Hashable {
            let date: Date
            let category: String
        }
            
        // 2. Group using the new struct instead of (Date, String)
        let grouped = Dictionary(grouping: items) { item in
            let day = calendar.startOfDay(for: item.date)
            return GroupKey(date: day, category: item.cluster?.name ?? "Miscellaneous")
        }
        
        // 3. Unpack the struct keys to build the final array
        for (key, groupItems) in grouped {
            let total = groupItems.reduce(0) { $0 + $1.amount }
            data.append(DailyExpense(date: key.date, category: key.category, amount: total))
        }
        
        return data.sorted { $0.date < $1.date }
    }
}

// MARK: - Helper Views
struct DailyExpense: Identifiable {
    let id = UUID()
    let date: Date
    let category: String
    let amount: Double
}

struct ScrubberAnnotationView: View {
    let date: Date
    let data: [DailyExpense]
    
    var body: some View {
        let calendar = Calendar.current
        let dailyItems = data.filter { calendar.isDate($0.date, inSameDayAs: date) }
        let dailyTotal = dailyItems.reduce(0) { $0 + $1.amount }
        
        if dailyTotal > 0 {
            VStack(alignment: .leading, spacing: 6) {
                Text(date, format: .dateTime.month().day().year())
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(String(format: "$%.2f", dailyTotal))
                    .font(.system(.headline, design: .rounded))
                    .monospacedDigit()
                
                if let topCategory = dailyItems.max(by: { $0.amount < $1.amount }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chart.pie.fill")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("Top: \(topCategory.category)")
                            .font(.caption2)
                            .foregroundColor(.primary)
                    }
                    .padding(.top, 2)
                }
            }
            .padding(14)
            .background(.ultraThickMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.12), radius: 10, y: 5)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )
            .offset(y: -10)
        }
    }
}
