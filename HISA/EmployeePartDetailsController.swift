import UIKit
import FirebaseDatabase
import SwiftUI
import Charts

class EmployeePartDetailsController: UIViewController {
    
    var partType: String!
    var userId: String!
    var partData: [(date: String, failureRate: Double, confidence: Double, classification: String)] = []
    var overallPartData: [(date: String, failureRate: Double, confidence: Double, classification: String)] = []
    var classifyData: [String: Int] = [:]
    var ref: DatabaseReference!
    
    private var scrollView: UIScrollView!
    private var contentView: UIView!
    private var hostingControllers: [UIHostingController<AnyView>] = []
    private var stackView: UIStackView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        ref = Database.database().reference()
        setupScrollView()
        fetchPartData()
        fetchOverallPartData()
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
        titleLabel.text = "\(partType!)"
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
    
    private func createStatsView() -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = .secondarySystemBackground
        container.layer.cornerRadius = 12
        
        let myFailureRate = calculateAverageFailureRate(from: partData)
        let myConfidence = calculateAverageConfidence(from: partData)
        let myTotalScans = partData.count
        
        let overallFailureRate = calculateAverageFailureRate(from: overallPartData)
        let overallConfidence = calculateAverageConfidence(from: overallPartData)
        let overallTotalScans = overallPartData.count
        
        let mainStack = UIStackView()
        mainStack.axis = .vertical
        mainStack.spacing = 24
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        
        let myStatsStack = createStatsRow(
            title: "Your Stats",
            failureRate: myFailureRate,
            confidence: myConfidence,
            totalScans: myTotalScans
        )
        
        let overallStatsStack = createStatsRow(
            title: "Overall Stats",
            failureRate: overallFailureRate,
            confidence: overallConfidence,
            totalScans: overallTotalScans
        )
        
        mainStack.addArrangedSubview(myStatsStack)
        mainStack.addArrangedSubview(overallStatsStack)
        
        container.addSubview(mainStack)
        
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: container.topAnchor, constant: 20),
            mainStack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            mainStack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),
            mainStack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -20)
        ])
        
        return container
    }
    
    private func createStatsRow(title: String, failureRate: Double, confidence: Double, totalScans: Int) -> UIView {
        let container = UIView()

        let sectionTitle = UILabel()
        sectionTitle.text = title
        sectionTitle.font = .systemFont(ofSize: 16, weight: .semibold)
        sectionTitle.textAlignment = .center
        sectionTitle.textColor = .secondaryLabel
        sectionTitle.translatesAutoresizingMaskIntoConstraints = false


        let titleContainer = UIView()
        titleContainer.translatesAutoresizingMaskIntoConstraints = false
        titleContainer.addSubview(sectionTitle)

        NSLayoutConstraint.activate([
            sectionTitle.topAnchor.constraint(equalTo: titleContainer.topAnchor),
            sectionTitle.centerXAnchor.constraint(equalTo: titleContainer.centerXAnchor),
            sectionTitle.bottomAnchor.constraint(equalTo: titleContainer.bottomAnchor, constant: -24)
        ])

        let statsStack = UIStackView()
        statsStack.axis = .horizontal
        statsStack.distribution = .fillEqually
        statsStack.spacing = 16
        statsStack.translatesAutoresizingMaskIntoConstraints = false

        let failureStat = createStatView(value: String(format: "%.1f%%", failureRate), label: "Failure Rate")
        let confidenceStat = createStatView(value: String(format: "%.1f%%", confidence), label: "Avg Confidence")
        let totalStat = createStatView(value: "\(totalScans)", label: "Total Scans")

        statsStack.addArrangedSubview(failureStat)
        statsStack.addArrangedSubview(confidenceStat)
        statsStack.addArrangedSubview(totalStat)

        let verticalStack = UIStackView(arrangedSubviews: [titleContainer, statsStack])
        verticalStack.axis = .vertical
        verticalStack.spacing = 0
        verticalStack.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(verticalStack)

        NSLayoutConstraint.activate([
            verticalStack.topAnchor.constraint(equalTo: container.topAnchor),
            verticalStack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            verticalStack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            verticalStack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -16)
        ])

        return container
    }

    private func calculateAverageFailureRate(from data: [(date: String, failureRate: Double, confidence: Double, classification: String)]) -> Double {
        guard !data.isEmpty else { return 0 }
        let totalFailures = data.reduce(0) { $0 + $1.failureRate }
        return totalFailures / Double(data.count)
    }

    private func calculateAverageConfidence(from data: [(date: String, failureRate: Double, confidence: Double, classification: String)]) -> Double {
        guard !data.isEmpty else { return 0 }
        let totalConfidence = data.reduce(0) { $0 + $1.confidence }
        return (totalConfidence / Double(data.count)) * 100
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
    
    private func fetchPartData() {
        let employeeRef = ref.child("users").child("employees").child(userId)
        
        employeeRef.observeSingleEvent(of: .value) { snapshot in
            guard snapshot.exists() else {
                print("No data found for employee")
                return
            }
            
            var newData: [(date: String, failureRate: Double, confidence: Double, classification: String)] = []
            var newClassifyData: [String: Int] = [:]
            
            // Process images
            let imagesRef = snapshot.childSnapshot(forPath: "images")
            for case let imageSnapshot as DataSnapshot in imagesRef.children {
                self.processMediaSnapshot(imageSnapshot, into: &newData, classifyData: &newClassifyData)
            }
            
            // Process videos
            let videosRef = snapshot.childSnapshot(forPath: "videos")
            for case let videoSnapshot as DataSnapshot in videosRef.children {
                self.processMediaSnapshot(videoSnapshot, into: &newData, classifyData: &newClassifyData)
            }
            
            DispatchQueue.main.async {
                self.partData = newData.sorted { $0.date < $1.date }
                self.classifyData = newClassifyData
                self.setupViews()
            }
        }
    }
    
    private func fetchOverallPartData() {
        let employeesRef = ref.child("users").child("employees")
        
        employeesRef.observeSingleEvent(of: .value) { snapshot in
            guard snapshot.exists() else {
                print("No data found for employees")
                return
            }
            
            var newOverallData: [(date: String, failureRate: Double, confidence: Double, classification: String)] = []
            
            for case let employeeSnapshot as DataSnapshot in snapshot.children {
                for mediaType in ["images", "videos"] {
                    let mediaRef = employeeSnapshot.childSnapshot(forPath: mediaType)
                    for case let mediaSnapshot as DataSnapshot in mediaRef.children {
                        if let partType = mediaSnapshot.childSnapshot(forPath: "part_type").value as? String,
                           partType.contains(self.partType),
                           let status = mediaSnapshot.childSnapshot(forPath: "status").value as? String,
                           let classification = mediaSnapshot.childSnapshot(forPath: "classification").value as? String,
                           let confidence = mediaSnapshot.childSnapshot(forPath: "confidence").value as? String,
                           let date = mediaSnapshot.childSnapshot(forPath: "date").value as? String {
                            
                            let failureRate = (status == "Good Part") ? 0.0 : 100.0
                            
                            newOverallData.append((date: date,
                                                   failureRate: failureRate,
                                                   confidence: Double(confidence)!,
                                                   classification: classification))
                        }
                    }
                }
            }
            
            DispatchQueue.main.async {
                self.overallPartData = newOverallData.sorted { $0.date < $1.date }
                self.setupViews()
            }
        }
    }

    
    private func processMediaSnapshot(_ snapshot: DataSnapshot,
                                    into data: inout [(date: String, failureRate: Double, confidence: Double, classification: String)],
                                    classifyData: inout [String: Int]) {
        guard
            let partType = snapshot.childSnapshot(forPath: "part_type").value as? String,
            partType.contains(self.partType),
            let status = snapshot.childSnapshot(forPath: "status").value as? String,
            let classification = snapshot.childSnapshot(forPath: "classification").value as? String,
            let confidence = snapshot.childSnapshot(forPath: "confidence").value as? String,
            let date = snapshot.childSnapshot(forPath: "date").value as? String
        else { return }
        
        let failureRate = (status == "Good Part") ? 0.0 : 100.0
        
        data.append((date: date,
                   failureRate: failureRate,
                   confidence: Double(confidence)!,
                   classification: classification))
        
        classifyData[classification] = (classifyData[classification] ?? 0) + 1
    }
}


