import UIKit
import FirebaseDatabase
import SwiftUI
import Charts

class PartDetailViewController: UIViewController {
    
    var partType: String!
    var partData: [(date: String, failureRate: Double, confidence: Double)] = []
    var ref: DatabaseReference!
    
    private var scrollView: UIScrollView!
    private var contentView: UIView!
    private var hostingControllers: [UIHostingController<AnyView>] = []
    
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
        view.addSubview(scrollView)
        
        contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }
    
    private func setupViews() {
        // Clear previous views
        hostingControllers.forEach { $0.removeFromParent() }
        contentView.subviews.forEach { $0.removeFromSuperview() }
        hostingControllers.removeAll()
        
        // Title Label
        let titleLabel = UILabel()
        titleLabel.text = partType
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textColor = .label
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        
        // Stats Summary
        let statsView = createStatsView()
        contentView.addSubview(statsView)
        
        // Create charts
        let failureRateChart = createChartView(title: "Failure Rate Over Time", chartType: .failureRate)
        let confidenceChart = createChartView(title: "Confidence Level Over Time", chartType: .confidence)
        
        // Layout constraints
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            statsView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            statsView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            statsView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            failureRateChart.view.topAnchor.constraint(equalTo: statsView.bottomAnchor, constant: 24),
            confidenceChart.view.topAnchor.constraint(equalTo: failureRateChart.view.bottomAnchor, constant: 24),
            
            failureRateChart.view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            failureRateChart.view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            confidenceChart.view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            confidenceChart.view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
        ])
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
        let Scanstat = createStatView(value: "\(totalScans)", label: "Scans")
        
        statsStack.addArrangedSubview(failureStat)
        statsStack.addArrangedSubview(confidenceStat)
        statsStack.addArrangedSubview(Scanstat)
        
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
        }
        
        let hostingController = UIHostingController(rootView: chartView)
        hostingController.view.backgroundColor = .clear
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        
        addChild(hostingController)
        contentView.addSubview(hostingController.view)
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
    
    func fetchPartData() {
        let employeesRef = ref.child("users").child("employees")
        
        employeesRef.observeSingleEvent(of: .value) { snapshot in
            guard snapshot.exists() else {
                print("No data found")
                return
            }
            
            var newData: [(date: String, failureRate: Double, confidence: Double)] = []
            
            for case let employeeSnapshot as DataSnapshot in snapshot.children {
                let imagesRef = employeeSnapshot.childSnapshot(forPath: "images")
                
                for case let imageSnapshot as DataSnapshot in imagesRef.children {
                    guard
                        let part_type = imageSnapshot.childSnapshot(forPath: "part_type").value as? String,
                        part_type.contains(self.partType),
                        let status = imageSnapshot.childSnapshot(forPath: "status").value as? String,
                        let confidence = imageSnapshot.childSnapshot(forPath: "confidence").value as? String,
                        let date = imageSnapshot.childSnapshot(forPath: "date").value as? String
                    else { continue }
                    
                    let failureRate = (status == "Good Part") ? 0.0 : 100.0
                    newData.append((date: date, failureRate: failureRate, confidence: Double(confidence)!))
                }
            }
            
            DispatchQueue.main.async {
                self.partData = newData.sorted { $0.date < $1.date }
                self.setupViews()
            }
        }
    }
}

// MARK: - Chart Types
enum ChartType {
    case failureRate
    case confidence
}

// MARK: - SwiftUI Chart Views
struct FailureRateChartView: View {
    let data: [(date: String, failureRate: Double, confidence: Double)]
    let title: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            if data.isEmpty {
                Text("No data available")
                    .frame(height: 200)
            } else {
                Chart {
                    ForEach(data, id: \.date) { item in
                        LineMark(
                            x: .value("Date", item.date),
                            y: .value("Failure Rate", item.failureRate)
                        )
                        .foregroundStyle(.red)
                        .interpolationMethod(.catmullRom)
                        
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
                        AxisGridLine()
                        if let dateStr = value.as(String.self) {
                            AxisValueLabel {
                                Text(dateStr)
                                    .font(.caption2)
                                    .rotationEffect(.degrees(-45))
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
}

struct ConfidenceChartView: View {
    let data: [(date: String, failureRate: Double, confidence: Double)]
    let title: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            if data.isEmpty {
                Text("No data available")
                    .frame(height: 200)
            } else {
                Chart {
                    ForEach(data, id: \.date) { item in
                        LineMark(
                            x: .value("Date", item.date),
                            y: .value("Confidence", item.confidence * 100)
                        )
                        .foregroundStyle(.blue)
                        .interpolationMethod(.catmullRom)
                        
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
                        AxisGridLine()
                        if let dateStr = value.as(String.self) {
                            AxisValueLabel {
                                Text(dateStr)
                                    .font(.caption2)
                                    .rotationEffect(.degrees(-45))
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
}

