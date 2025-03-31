import UIKit
import FirebaseDatabase
import SwiftUI
import Charts

class PartDetailViewController: UIViewController {

    var partType: String!
    var partData: [(date: String, failureRate: Double, confidence: Double, classification: String)] = []
    var classifyData: [String: Int] = [:]
    var ref: DatabaseReference!
    var dateRange: (Date, Date)? // Added to support filtering by date

    private var scrollView: UIScrollView!
    private var contentView: UIView!
    private var hostingControllers: [UIHostingController<AnyView>] = []
    private var stackView: UIStackView!
    
    private let dateFormatter: DateFormatter = {
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd"
            return df
        }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        ref = Database.database().reference()
        setupScrollView()
        fetchPartData()
    }

    private func setupScrollView() {
        scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)

        contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)

        stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stackView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }

    private func setupViews() {
        // Clear previous views
        hostingControllers.forEach { $0.removeFromParent() }
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        hostingControllers.removeAll()

        // Title Label
        let titleLabel = UILabel()
        titleLabel.text = partType
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textColor = .label
        titleLabel.textAlignment = .center
        stackView.addArrangedSubview(titleLabel)

        // Stats Summary
        let statsView = createStatsView()
        stackView.addArrangedSubview(statsView)

        // Create charts
        let failureRateChart = createChartView(title: "Failure Rate Over Time", chartType: .failureRate)
        let confidenceChart = createChartView(title: "Confidence Level Over Time", chartType: .confidence)
        let classifyChart = createChartView(title: "Defect Type Distribution", chartType: .classify)

        // Add charts to stack view
        stackView.addArrangedSubview(failureRateChart.view)
        stackView.addArrangedSubview(classifyChart.view)
        stackView.addArrangedSubview(confidenceChart.view)

        // Set fixed heights for charts
        failureRateChart.view.heightAnchor.constraint(equalToConstant: 250).isActive = true
        classifyChart.view.heightAnchor.constraint(equalToConstant: 300).isActive = true
        confidenceChart.view.heightAnchor.constraint(equalToConstant: 250).isActive = true

        // Add spacing between views
        stackView.setCustomSpacing(20, after: titleLabel)
        stackView.setCustomSpacing(24, after: statsView)
        stackView.setCustomSpacing(24, after: failureRateChart.view)
        stackView.setCustomSpacing(24, after: classifyChart.view)
    }

    @IBAction func filterButtonTapped(_ sender: UIButton) {
        // This method is needed if the button in storyboard is connected to this selector
        print("Filter button tapped")
    }

    func fetchPartData() {
        let employeesRef = ref.child("users").child("employees")

        employeesRef.observeSingleEvent(of: .value) { snapshot in
            guard snapshot.exists() else {
                print("No data found")
                return
            }

            var newData: [(date: String, failureRate: Double, confidence: Double, classification: String)] = []
            var newclassifyData: [String: Int] = [:]

            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd"

            for case let employeeSnapshot as DataSnapshot in snapshot.children {
                let imagesRef = employeeSnapshot.childSnapshot(forPath: "images")
                let videosRef = employeeSnapshot.childSnapshot(forPath: "videos")

                let combined = (imagesRef.children.allObjects + videosRef.children.allObjects) as! [DataSnapshot]

                for snapshot in combined {
                    guard
                        let part_type = snapshot.childSnapshot(forPath: "part_type").value as? String,
                        part_type.contains(self.partType),
                        let status = snapshot.childSnapshot(forPath: "status").value as? String,
                        let classification = snapshot.childSnapshot(forPath: "classification").value as? String,
                        let confidence = snapshot.childSnapshot(forPath: "confidence").value as? String,
                        let dateStr = snapshot.childSnapshot(forPath: "date").value as? String,
                        let dateObj = self.dateFormatter.date(from: dateStr)
                    else { continue }

                    if let range = self.dateRange, !(dateObj >= range.0 && dateObj <= range.1) {
                                            continue
                                        }

                    let failureRate = (status == "Good Part") ? 0.0 : 100.0
                    newclassifyData[classification] = (newclassifyData[classification] ?? 0) + 1
                    newData.append((date: dateStr, failureRate: failureRate, confidence: Double(confidence)!, classification))
                }
            }

            DispatchQueue.main.async {
                self.partData = newData.sorted { $0.date < $1.date }
                self.classifyData = newclassifyData
                self.setupViews()
            }
        }
    }

    private func createStatsView() -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = .secondarySystemBackground
        container.layer.cornerRadius = 12

        let failureRate = calculateAverageFailureRate()
        let avgConfidence = calculateAverageConfidence()
        let totalScans = partData.count

        let statsStack = UIStackView()
        statsStack.axis = .horizontal
        statsStack.distribution = .fillEqually
        statsStack.spacing = 8
        statsStack.translatesAutoresizingMaskIntoConstraints = false

        let failureStat = createStatView(value: String(format: "%.1f%%", failureRate), label: "Failure Rate")
        let confidenceStat = createStatView(value: String(format: "%.1f%%", avgConfidence), label: "Avg Confidence")
        let scanStat = createStatView(value: "\(totalScans)", label: "Scans")

        statsStack.addArrangedSubview(failureStat)
        statsStack.addArrangedSubview(confidenceStat)
        statsStack.addArrangedSubview(scanStat)

        container.addSubview(statsStack)

        NSLayoutConstraint.activate([
            statsStack.topAnchor.constraint(equalTo: container.topAnchor, constant: 25),
            statsStack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 25),
            statsStack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -25),
            statsStack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -25)
        ])

        return container
    }

    private func createStatView(value: String, label: String) -> UIView {
        let container = UIView()

        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = .systemFont(ofSize: 18, weight: .bold)
        valueLabel.textAlignment = .center
        valueLabel.textColor = .label

        let descriptionLabel = UILabel()
        descriptionLabel.text = label
        descriptionLabel.font = .systemFont(ofSize: 14, weight: .medium)
        descriptionLabel.textAlignment = .center
        descriptionLabel.textColor = .secondaryLabel

        let stack = UIStackView(arrangedSubviews: [valueLabel, descriptionLabel])
        stack.axis = .vertical
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])

        return container
    }

    private func createChartView(title: String, chartType: ChartType) -> UIHostingController<AnyView> {
        let chartView: AnyView

        switch chartType {
        case .failureRate:
            chartView = AnyView(FailureRateChartView(data: partData, title: title))
        case .confidence:
            chartView = AnyView(ConfidenceChartView(data: partData, title: title))
        case .classify:
            chartView = AnyView(classifyChartView(data: classifyData, title: title))
        }

        let hostingController = UIHostingController(rootView: chartView)
        hostingController.view.backgroundColor = .clear
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false

        addChild(hostingController)
        hostingController.didMove(toParent: self)
        hostingControllers.append(hostingController)

        return hostingController
    }

    private func calculateAverageFailureRate() -> Double {
        guard !partData.isEmpty else { return 0 }
        let totalFailures = partData.reduce(0) { $0 + $1.failureRate }
        return totalFailures / Double(partData.count)
    }

    private func calculateAverageConfidence() -> Double {
        guard !partData.isEmpty else { return 0 }
        let totalConfidence = partData.reduce(0) { $0 + $1.confidence }
        return (totalConfidence / Double(partData.count)) * 100
    }
}

// MARK: - Chart Types
enum ChartType {
    case failureRate
    case confidence
    case classify
}

// MARK: - SwiftUI Chart Views

struct FailureRateChartView: View {
    let data: [(date: String, failureRate: Double, confidence: Double, classification: String)]
    let title: String
    
    private let dateFormatter: DateFormatter = {
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd"
            return df
        }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            let aggregatedData = aggregateFailureRatePerDay(data)
            
            if aggregatedData.isEmpty {
                Text("No data available")
                    .frame(height: 200)
            } else {
                Chart {
                    ForEach(aggregatedData, id: \.date) { item in
                        LineMark(
                            x: .value("Date", item.date),
                            y: .value("Failure Rate", item.failureRate)
                        )
                        .foregroundStyle(.red)
                        .interpolationMethod(.linear)
                        
                        PointMark(
                            x: .value("Date", item.date),
                            y: .value("Failure Rate", item.failureRate)
                        )
                        .symbolSize(12)
                        .foregroundStyle(.red)
                    }
                }
                .chartYScale(domain: 0...100)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let rate = value.as(Double.self) {
                                Text("\(Int(rate))%")
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic) { value in
                        if let date = value.as(Date.self) {
                            AxisGridLine()
                            AxisTick()
                            AxisValueLabel {
                                Text(date, format: .dateTime.day().month())
                            }
                        }
                    }
                }
                .frame(height: 200)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
    
    /// Aggregates failure rates per day by averaging them
    private func aggregateFailureRatePerDay(_ data: [(date: String, failureRate: Double, confidence: Double, classification: String)]) -> [(date: Date, failureRate: Double)] {
            var dailySums: [Date: (total: Double, count: Int)] = [:]
            
            for item in data {
                if let date = dateFormatter.date(from: item.date) {
                    let calendar = Calendar.current
                    let startOfDay = calendar.startOfDay(for: date)
                    if let existing = dailySums[startOfDay] {
                        dailySums[startOfDay] = (existing.total + item.failureRate, existing.count + 1)
                    } else {
                        dailySums[startOfDay] = (item.failureRate, 1)
                    }
                }
            }
            
            return dailySums.map { (date, stats) in
                (date: date, failureRate: stats.total / Double(stats.count))
            }
            .sorted { $0.date < $1.date }
        }
}


import SwiftUI
import Charts

struct ConfidenceChartView: View {
    let data: [(date: String, failureRate: Double, confidence: Double, classification: String)]
    let title: String
    
    private let dateFormatter: DateFormatter = {
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd"
            return df
        }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            let aggregatedData = aggregateConfidencePerDay(data)
            
            if aggregatedData.isEmpty {
                Text("No data available")
                    .frame(height: 200)
            } else {
                Chart {
                    ForEach(aggregatedData, id: \.date) { item in
                        LineMark(
                            x: .value("Date", item.date),
                            y: .value("Confidence", item.confidence * 100)
                        )
                        .foregroundStyle(.blue)
                        .interpolationMethod(.linear)
                        
                        PointMark(
                            x: .value("Date", item.date),
                            y: .value("Confidence", item.confidence * 100)
                        )
                        .symbolSize(12)
                        .foregroundStyle(.blue)
                    }
                }
                .chartYScale(domain: 0...100)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let rate = value.as(Double.self) {
                                Text("\(Int(rate))%")
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic) { value in
                        if let date = value.as(Date.self) {
                            AxisGridLine()
                            AxisTick()
                            AxisValueLabel {
                                Text(date, format: .dateTime.day().month())
                            }
                        }
                    }
                }
                .frame(height: 200)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
    
    /// Aggregates confidence scores per day by averaging them
    private func aggregateConfidencePerDay(_ data: [(date: String, failureRate: Double, confidence: Double, classification: String)]) -> [(date: Date, confidence: Double)] {
            var dailySums: [Date: (total: Double, count: Int)] = [:]
            
            for item in data {
                if let date = dateFormatter.date(from: item.date) {
                    let calendar = Calendar.current
                    let startOfDay = calendar.startOfDay(for: date)
                    if let existing = dailySums[startOfDay] {
                        dailySums[startOfDay] = (existing.total + item.confidence, existing.count + 1)
                    } else {
                        dailySums[startOfDay] = (item.confidence, 1)
                    }
                }
            }
            
            return dailySums.map { (date, stats) in
                (date: date, confidence: stats.total / Double(stats.count))
            }
            .sorted { $0.date < $1.date }
        }
}


struct classifyChartView: View {
    let data: [String: Int]
    let title: String
    
    // Convert dictionary to an array of identifiable structs
    private var chartData: [DefectData] {
        data.map { DefectData(type: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            if chartData.isEmpty {
                Text("No defect data available")
                    .frame(height: 200)
            } else {
                Chart {
                    ForEach(chartData) { item in
                        if #available(iOS 17.0, *) {
                            SectorMark(
                                angle: .value(item.type, item.count),
                                innerRadius: .ratio(0.6),
                                angularInset: 1.5
                            )
                            .cornerRadius(5)
                            .foregroundStyle(by: .value("Defect Type", item.type))
                            .annotation(position: .overlay) {
                                Text("\(item.count)")
                                    .font(.caption)
                                    .foregroundColor(.white)
                            }
                        } else {
                            // Fallback on earlier versions
                        }
                    }
                }
                .chartLegend(position: .bottom, alignment: .center, spacing: 16)
                .frame(height: 200)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
    
    // Helper struct to make data identifiable
    private struct DefectData: Identifiable {
        let type: String
        let count: Int
        var id: String { type }
    }
}

