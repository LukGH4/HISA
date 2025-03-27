import UIKit
import FirebaseDatabase
import SwiftUI
import Charts

class ComparisonViewController: UIViewController {
    
    var selectedParts: [String] = [] // Passed from previous screen
    var partsData: [String: [(date: String, goodCount: Int, badCount: Int, confidence: Double)]] = [:]
    
    private var ref: DatabaseReference!
    private var loadingIndicator: UIActivityIndicatorView!
    private var hostingController: UIHostingController<ComparisonChartView>?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Part Comparison"
        ref = Database.database().reference()
        
        setupLoadingIndicator()
        fetchComparisonData()
    }
    
    private func setupLoadingIndicator() {
        loadingIndicator = UIActivityIndicatorView(style: .large)
        loadingIndicator.center = view.center
        loadingIndicator.hidesWhenStopped = true
        view.addSubview(loadingIndicator)
        loadingIndicator.startAnimating()
    }
    
    private func fetchComparisonData() {
        let group = DispatchGroup()
        
        for partName in selectedParts {
            group.enter()
            fetchDataForPart(partName) { data in
                self.partsData[partName] = data
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            self.loadingIndicator.stopAnimating()
            self.setupChartView()
        }
    }
    
    private func fetchDataForPart(_ partName: String, completion: @escaping ([(date: String, goodCount: Int, badCount: Int, confidence: Double)]) -> Void) {
        let employeesRef = ref.child("users/employees")
        var partData: [(date: String, goodCount: Int, badCount: Int, confidence: Double)] = []
        
        employeesRef.observeSingleEvent(of: .value) { snapshot in
            guard snapshot.exists() else {
                completion([])
                return
            }
            
            for case let employeeSnapshot as DataSnapshot in snapshot.children {
                let imagesRef = employeeSnapshot.childSnapshot(forPath: "images")
                
                for case let imageSnapshot as DataSnapshot in imagesRef.children {
                    guard let partType = imageSnapshot.childSnapshot(forPath: "part_type").value as? String,
                          partType == partName,
                          let status = imageSnapshot.childSnapshot(forPath: "status").value as? String,
                          let confidence = imageSnapshot.childSnapshot(forPath: "confidence").value as? Double,
                          let date = imageSnapshot.childSnapshot(forPath: "date").value as? String else {
                        continue
                    }
                    
                    // Initialize or update counts for this date
                    if let index = partData.firstIndex(where: { $0.date == date }) {
                        if status == "Good Part" {
                            partData[index].goodCount += 1
                        } else {
                            partData[index].badCount += 1
                        }
                    } else {
                        let newEntry = (
                            date: date,
                            goodCount: status == "Good Part" ? 1 : 0,
                            badCount: status == "Good Part" ? 0 : 1,
                            confidence: confidence
                        )
                        partData.append(newEntry)
                    }
                }
            }
            
            // Sort by date
            let sortedData = partData.sorted { $0.date < $1.date }
            completion(sortedData)
        }
    }
    
    private func setupChartView() {
        // Remove existing hosting controller if present
        hostingController?.willMove(toParent: nil)
        hostingController?.view.removeFromSuperview()
        hostingController?.removeFromParent()
        
        let chartView = ComparisonChartView(
            selectedParts: partsData,
            partNames: selectedParts
        )
        
        hostingController = UIHostingController(rootView: chartView)
        guard let hostingController = hostingController else { return }
        
        addChild(hostingController)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)
        
        NSLayoutConstraint.activate([
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            hostingController.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            hostingController.view.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }
}

struct ComparisonChartView: View {
    var selectedParts: [String: [(date: String, goodCount: Int, badCount: Int, confidence: Double)]]
    var partNames: [String]
    
    private var allDates: [String] {
        selectedParts.values.flatMap { $0.map { $0.date } }.unique().sorted()
    }
    
    private func failureRate(for data: (goodCount: Int, badCount: Int)) -> Double {
        let total = data.goodCount + data.badCount
        return total > 0 ? (Double(data.badCount) / Double(total)) * 100 : 0
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Failure Rate Comparison")
                .font(.headline)
                .padding(.horizontal)
            
            if selectedParts.isEmpty {
                Text("No data available for selected parts")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                Chart {
                    ForEach(partNames, id: \.self) { partName in
                        if let partData = selectedParts[partName], !partData.isEmpty {
                            ForEach(partData, id: \.date) { data in
                                LineMark(
                                    x: .value("Date", data.date),
                                    y: .value("Failure Rate", failureRate(for: (data.goodCount, data.badCount)))
                                )
                                .foregroundStyle(by: .value("Part Type", partName))
                                .symbol(by: .value("Part Type", partName))
                                
                                PointMark(
                                    x: .value("Date", data.date),
                                    y: .value("Failure Rate", failureRate(for: (data.goodCount, data.badCount)))
                                )
                                .foregroundStyle(by: .value("Part Type", partName))
                                .symbolSize(100)
                            }
                        }
                    }
                }
                .chartLegend(position: .bottom, alignment: .leading)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine()
                        AxisTick()
                        if let rate = value.as(Double.self) {
                            AxisValueLabel("\(rate.formatted(.number.precision(.fractionLength(0))))%")
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { value in
                        AxisGridLine()
                        AxisTick()
                        if let date = value.as(String.self) {
                            AxisValueLabel {
                                Text(date)
                                    .font(.caption2)
                            }
                        }
                    }
                }
                .frame(height: 300)
                .padding()
            }
            
            // Confidence information
            if let firstPart = partNames.first, let firstData = selectedParts[firstPart] {
                let avgConfidence = firstData.map { $0.confidence }.average()
                Text("Average confidence: \(avgConfidence.formatted(.percent))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }
        }
    }
}

// Helper extensions
extension Array where Element: Hashable {
    func unique() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}

extension Array where Element == Double {
    func average() -> Double {
        guard !isEmpty else { return 0 }
        return reduce(0, +) / Double(count)
    }
}
