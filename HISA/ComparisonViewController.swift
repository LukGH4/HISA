import UIKit
import FirebaseDatabase
import SwiftUI
import Charts

class ComparisonViewController: UIViewController {

    var selectedParts: [String] = [] // Passed from previous screen
    var partsData: [String: [(date: Date, goodCount: Int, badCount: Int, confidence: Double)]] = [:]
    var dateRange: (Date, Date)? // Added date filter support

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
        guard !selectedParts.isEmpty else {
            loadingIndicator.stopAnimating()
            showNoDataMessage()
            return
        }

        let group = DispatchGroup()

        for partName in selectedParts {
            group.enter()
            fetchDataForPart(partName) { data in
                DispatchQueue.main.async {
                    if !data.isEmpty {
                        self.partsData[partName] = data
                    }
                    group.leave()
                }
            }
        }

        group.notify(queue: .main) {
            self.loadingIndicator.stopAnimating()
            if self.partsData.isEmpty {
                self.showNoDataMessage()
            } else {
                self.setupChartView()
            }
        }
    }

    private func showNoDataMessage() {
        let label = UILabel()
        label.text = "No data available for selected parts"
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func fetchDataForPart(_ partName: String, completion: @escaping ([(date: Date, goodCount: Int, badCount: Int, confidence: Double)]) -> Void) {
        let employeesRef = ref.child("users/employees")
        var partData: [(date: Date, goodCount: Int, badCount: Int, confidence: Double)] = []

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)

        employeesRef.observeSingleEvent(of: .value) { snapshot in
            guard snapshot.exists() else {
                DispatchQueue.main.async {
                    completion([])
                }
                return
            }

            for case let employeeSnapshot as DataSnapshot in snapshot.children {
                let imagesRef = employeeSnapshot.childSnapshot(forPath: "images")

                for case let imageSnapshot as DataSnapshot in imagesRef.children {
                    guard let partType = imageSnapshot.childSnapshot(forPath: "part_type").value as? String,
                          partType == partName,
                          let status = imageSnapshot.childSnapshot(forPath: "status").value as? String,
                          let confidence = imageSnapshot.childSnapshot(forPath: "confidence").value as? String,
                          let dateString = imageSnapshot.childSnapshot(forPath: "date").value as? String,
                          let date = dateFormatter.date(from: dateString) else {
                        continue
                    }

                    if let range = self.dateRange, !(date >= range.0 && date <= range.1) {
                        continue
                    }

                    let normalizedDate = Calendar.current.startOfDay(for: date)

                    if let index = partData.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: normalizedDate) }) {
                        if status == "Good Part" {
                            partData[index].goodCount += 1
                        } else {
                            partData[index].badCount += 1
                        }
                        partData[index].confidence = max(partData[index].confidence, Double(confidence)!)
                    } else {
                        let newEntry = (
                            date: normalizedDate,
                            goodCount: status == "Good Part" ? 1 : 0,
                            badCount: status == "Good Part" ? 0 : 1,
                            confidence: Double(confidence)!
                        )
                        partData.append(newEntry)
                    }
                }
            }

            let sortedData = partData.sorted { $0.date < $1.date }

            DispatchQueue.main.async {
                completion(sortedData)
            }
        }
    }

    private func setupChartView() {
        if let existingController = hostingController {
            existingController.willMove(toParent: nil)
            existingController.view.removeFromSuperview()
            existingController.removeFromParent()
        }

        let chartsView = ComparisonChartView(
            selectedParts: partsData,
            partNames: selectedParts
        )

        let newHostingController = UIHostingController(rootView: chartsView)
        newHostingController.view.backgroundColor = .clear
        newHostingController.view.translatesAutoresizingMaskIntoConstraints = false

        addChild(newHostingController)
        view.addSubview(newHostingController.view)
        newHostingController.didMove(toParent: self)

        NSLayoutConstraint.activate([
            newHostingController.view.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            newHostingController.view.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            newHostingController.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            newHostingController.view.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])

        hostingController = newHostingController
    }
}

struct ComparisonChartView: View {
    var selectedParts: [String: [(date: Date, goodCount: Int, badCount: Int, confidence: Double)]]
    var partNames: [String]

    private func failureRate(for data: (goodCount: Int, badCount: Int)) -> Double {
        let total = data.goodCount + data.badCount
        return total > 0 ? (Double(data.badCount) / Double(total)) * 100 : 0
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                VStack(alignment: .leading) {
                    Text("Failure Rate (%)")
                        .font(.headline)
                        .padding(.horizontal)

                    Chart {
                        ForEach(partNames, id: \.self) { partName in
                            if let partData = selectedParts[partName] {
                                ForEach(partData, id: \.date) { data in
                                    let rate = failureRate(for: (data.goodCount, data.badCount))

                                    LineMark(
                                        x: .value("Date", data.date),
                                        y: .value("Failure Rate", rate)
                                    )
                                    .foregroundStyle(by: .value("Part Type", partName))
                                    .interpolationMethod(.linear)
                                    .lineStyle(StrokeStyle(lineWidth: 2))
                                    .position(by: .value("Part Type", partName))
                                    .alignsMarkStylesWithPlotArea()

                                    PointMark(
                                        x: .value("Date", data.date),
                                        y: .value("Failure Rate", rate)
                                    )
                                    .foregroundStyle(by: .value("Part Type", partName))
                                    .symbolSize(60)
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
                    .chartYAxis {
                        AxisMarks(position: .leading)
                    }
                    .chartLegend(position: .bottom, alignment: .center, spacing: 20)
                    .frame(height: 300)
                    .padding()
                }

                VStack(alignment: .leading) {
                    Text("Confidence Levels (%)")
                        .font(.headline)
                        .padding(.horizontal)

                    Chart {
                        ForEach(partNames, id: \.self) { partName in
                            if let partData = selectedParts[partName] {
                                ForEach(partData, id: \.date) { data in
                                    let confidencePercent = data.confidence * 100

                                    LineMark(
                                        x: .value("Date", data.date),
                                        y: .value("Confidence", confidencePercent)
                                    )
                                    .foregroundStyle(by: .value("Part Type", partName))
                                    .interpolationMethod(.linear)
                                    .lineStyle(StrokeStyle(lineWidth: 2))
                                    .position(by: .value("Part Type", partName))
                                    .alignsMarkStylesWithPlotArea()

                                    PointMark(
                                        x: .value("Date", data.date),
                                        y: .value("Confidence", confidencePercent)
                                    )
                                    .foregroundStyle(by: .value("Part Type", partName))
                                    .symbolSize(60)
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
                    .chartYAxis {
                        AxisMarks(position: .leading)
                    }
                    .chartLegend(position: .bottom, alignment: .center, spacing: 20)
                    .frame(height: 300)
                    .padding()
                }
            }
            .padding(.vertical)
        }
        .scrollIndicators(.hidden)
    }
}
