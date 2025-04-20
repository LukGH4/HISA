import UIKit
import Charts
import SwiftUI
import FirebaseDatabase
import FirebaseAuth

class EmployeeStatsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var employeeTable: UITableView!
    
    var ref: DatabaseReference!
    var partTypes: [String: [String: Any]] = [:]
    var partTypeNames: [String] = []
    var scanHistory: [(date: String, count: Int)] = []
    var overallScanHistory: [(date: String, count: Int)] = []

    
    let userId = Auth.auth().currentUser?.uid ?? "unknown_user"
    let failureRateThreshold: Double = -1.0
    let dateFormatter = DateFormatter()
    
    enum Section: Int, CaseIterable {
        case parts = 0
        case charts
        
        var title: String {
            switch self {
            case .parts: return "Parts Statistics"
            case .charts: return "Scan Charts"
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        ref = Database.database().reference()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        setupTableView()
        employeeTable.separatorStyle = .none
        fetchEmployeeData()
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        employeeTable.refreshControl = refreshControl
    }
    
    private func setupTableView() {
        employeeTable.dataSource = self
        employeeTable.delegate = self
        employeeTable.rowHeight = UITableView.automaticDimension
        employeeTable.estimatedRowHeight = 60
        employeeTable.showsVerticalScrollIndicator = false
        employeeTable.register(EmployeeStatsCell.self, forCellReuseIdentifier: "StatsCell")
        employeeTable.register(ChartTableViewCell.self, forCellReuseIdentifier: "ChartCell")
    }
    
    private func updateCharts() {
        // Update the charts section
        employeeTable.reloadSections(IndexSet(integer: Section.charts.rawValue), with: .none)
    }

    private func fetchEmployeeData() {
        fetchEmployeeParts()
        fetchScanHistory()
        fetchOverallScanHistory()
    }

    
    private func fetchEmployeeParts() {
        let employeeRef = ref.child("users").child("employees").child(userId)

        employeeRef.observeSingleEvent(of: .value, with: { snapshot in
            guard snapshot.exists() else {
                print("No data found for employee")
                return
            }
            
            var localPartTypes: [String: [String: Any]] = [:]
            let imagesRef = snapshot.childSnapshot(forPath: "images")
            let videosRef = snapshot.childSnapshot(forPath: "videos")

            // Process images
            for imageSnapshot in imagesRef.children.allObjects as! [DataSnapshot] {
                self.processMediaSnapshot(imageSnapshot, into: &localPartTypes)
            }
            
            // Process videos
            for videoSnapshot in videosRef.children.allObjects as! [DataSnapshot] {
                self.processMediaSnapshot(videoSnapshot, into: &localPartTypes)
            }

            DispatchQueue.main.async {
                self.partTypes = localPartTypes
                self.partTypeNames = Array(self.partTypes.keys)
                self.employeeTable.reloadData()
                self.updateCharts()
            }
        }) { error in
            print("Error retrieving employee data: \(error.localizedDescription)")
        }
    }
    
    private func fetchOverallScanHistory() {
        let employeesRef = ref.child("users").child("employees")
        
        employeesRef.observeSingleEvent(of: .value, with: { snapshot in
            var scanCounts: [String: Int] = [:]
            
            if snapshot.exists() {
                for employeeSnapshot in snapshot.children.allObjects as! [DataSnapshot] {
                    ["images", "videos"].forEach { mediaType in
                        let mediaRef = employeeSnapshot.childSnapshot(forPath: mediaType)
                        for mediaSnapshot in mediaRef.children.allObjects as! [DataSnapshot] {
                            if let date = mediaSnapshot.childSnapshot(forPath: "date").value as? String {
                                scanCounts[date] = (scanCounts[date] ?? 0) + 1
                            }
                        }
                    }
                }
                
                var history = scanCounts.map { (date: $0.key, count: $0.value) }
                    .sorted { $0.date > $1.date }
                
                if history.count > 30 {
                    history = Array(history[0..<30])
                }
                
                DispatchQueue.main.async {
                    self.overallScanHistory = history
                    self.updateCharts()
                }
            }
        }) { error in
            print("Error retrieving overall scan history: \(error.localizedDescription)")
        }
    }

    
    private func processMediaSnapshot(_ snapshot: DataSnapshot, into partTypes: inout [String: [String: Any]]) {
        if let partType = snapshot.childSnapshot(forPath: "part_type").value as? String,
           let status = snapshot.childSnapshot(forPath: "status").value as? String {
            var partTypeEntry = partTypes[partType] ?? ["good": 0, "bad": 0]
            status == "Good Part" ? (partTypeEntry["good"] = (partTypeEntry["good"] as? Int ?? 0) + 1) :
                                  (partTypeEntry["bad"] = (partTypeEntry["bad"] as? Int ?? 0) + 1)
            partTypes[partType] = partTypeEntry
        }
    }
    
    private func fetchScanHistory() {
        let employeeRef = ref.child("users").child("employees").child(userId)
        
        employeeRef.observeSingleEvent(of: .value, with: { snapshot in
            var scanCounts: [String: Int] = [:]
            
            if snapshot.exists() {
                // Process both images and videos for timestamps
                ["images", "videos"].forEach { mediaType in
                    let mediaRef = snapshot.childSnapshot(forPath: mediaType)
                    for mediaSnapshot in mediaRef.children.allObjects as! [DataSnapshot] {
                        if let date = mediaSnapshot.childSnapshot(forPath: "date").value as? String {
                            scanCounts[date] = (scanCounts[date] ?? 0) + 1
                        }
                    }
                }
                
                // Sort and limit to 30 days
                var history = scanCounts.map { (date: $0.key, count: $0.value) }
                    .sorted { $0.date > $1.date }
                
                if history.count > 30 {
                    history = Array(history[0..<30])
                }
                
                DispatchQueue.main.async {
                    self.scanHistory = history
                    self.updateCharts()
                }
            }
        }) { error in
            print("Error retrieving scan history: \(error.localizedDescription)")
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return Section(rawValue: section)?.title
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section) {
        case .parts: return partTypeNames.count
        case .charts: return 1
        default: return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch Section(rawValue: indexPath.section) {
        case .parts:
            let cell = tableView.dequeueReusableCell(withIdentifier: "StatsCell", for: indexPath) as! EmployeeStatsCell
            let partType = partTypeNames[indexPath.row]
            if let counts = partTypes[partType],
               let good = counts["good"] as? Int,
               let bad = counts["bad"] as? Int {
                cell.configure(with: partType, goodCount: good, badCount: bad)
            }
            return cell
            
        case .charts:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ChartCell", for: indexPath) as! ChartTableViewCell
            
            // Prepare data for charts
            var partsData: [String: Double] = [:]
            for (partType, counts) in partTypes {
                if let good = counts["good"] as? Int, let bad = counts["bad"] as? Int {
                    partsData["\(partType)"] = Double(good) + Double(bad)
                    
                }
            }
            
            cell.configure(
                partsData: partsData,
                scanHistoryData: scanHistory.map { ($0.date, $0.count) },
                overallScanHistoryData: overallScanHistory.map { ($0.date, $0.count) }
            )

            return cell
            
        default:
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if Section(rawValue: indexPath.section) == .charts {
            return 610 // Height for the chart cell
        }
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if Section(rawValue: indexPath.section) == .parts {
            let partType = partTypeNames[indexPath.row]
            performSegue(withIdentifier: "showEmployeePart", sender: partType)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showEmployeePart",
           let partType = sender as? String,
           let detailVC = segue.destination as? EmployeePartDetailsController {
            detailVC.partType = partType
            detailVC.userId = userId
        }
    }
    
    @objc private func refreshData() {
        fetchEmployeeData()
        employeeTable.refreshControl?.endRefreshing()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchEmployeeData()
    }
}

class ChartTableViewCell: UITableViewCell {
    private var hostingController: UIHostingController<AnyView>?
    
    override func prepareForReuse() {
        super.prepareForReuse()
        hostingController?.view.removeFromSuperview()
        hostingController = nil
    }
    
    func configure(partsData: [String: Double], scanHistoryData: [(String, Int)], overallScanHistoryData: [(String, Int)]) {
        let chartsView = ChartsView(
            partsData: partsData,
            scanHistoryData: scanHistoryData,
            overallScanHistoryData: overallScanHistoryData
        )
        hostingController = UIHostingController(rootView: AnyView(chartsView))

        guard let hostView = hostingController?.view else { return }
        contentView.addSubview(hostView)
        hostView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            hostView.topAnchor.constraint(equalTo: contentView.topAnchor),
            hostView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            hostView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            hostView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])

        hostingController?.didMove(toParent: self.parentViewController)
    }

}

extension UIView {
    var parentViewController: UIViewController? {
        var parentResponder: UIResponder? = self
        while parentResponder != nil {
            parentResponder = parentResponder?.next
            if let viewController = parentResponder as? UIViewController {
                return viewController
            }
        }
        return nil
    }
}

// Combined Charts View
struct ChartsView: View {
    let partsData: [String: Double]
    let scanHistoryData: [(String, Int)]
    let overallScanHistoryData: [(String, Int)] // ➡️ New
    
    var body: some View {
        VStack(spacing: 16) {
            PartsDistributionChartView(data: partsData)
            ScanHistoryChartView(data: scanHistoryData, overallData: overallScanHistoryData) // ➡️ Pass it
        }
    }
}


// Parts Distribution Chart View
struct PartsDistributionChartView: View {
    let data: [String: Double]
    
    private var chartData: [PartData] {
        data.map { PartData(type: $0.key, value: $0.value) }
            .sorted { $0.value > $1.value }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Parts Distribution")
                .font(.headline)
                .foregroundColor(.primary)
            
            if chartData.isEmpty {
                Text("No parts data available")
                    .frame(height: 200)
            } else {
                Chart {
                    ForEach(chartData) { item in
                        if #available(iOS 17.0, *) {
                            SectorMark(
                                angle: .value(item.type, item.value),
                                innerRadius: .ratio(0.6),
                                angularInset: 1.5
                            )
                            .foregroundStyle(by: .value("Part Type", item.type))
                            .annotation(position: .overlay) {
                                Text("\(Int(item.value))")
                                    .font(.caption)
                                    .foregroundColor(.white)
                            }
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
    
    private struct PartData: Identifiable {
        let type: String
        let value: Double
        var id: String { type }
    }
}

struct ScanEntry: Identifiable {
    let id = UUID()
    let date: Date
    let count: Int
    let series: String
}

// Scan History Chart View
struct ScanHistoryChartView: View {
    let myData: [(date: Date, count: Int)]
    let overallData: [(date: Date, count: Int)]
    @State private var showOverallScans = true

    private let dateFormatter: DateFormatter

    init(data: [(date: String, count: Int)], overallData: [(date: String, count: Int)]) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        self.dateFormatter = formatter

        self.myData = data.compactMap { (dateString, count) in
            guard let date = formatter.date(from: dateString) else { return nil }
            return (date: date, count: count)
        }

        self.overallData = overallData.compactMap { (dateString, count) in
            guard let date = formatter.date(from: dateString) else { return nil }
            return (date: date, count: count)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Scan History")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                VStack(spacing: 2) { // 🔥 toggle and label stacked vertically
                    Toggle("", isOn: $showOverallScans.animation(.easeInOut))
                        .labelsHidden()
                        .toggleStyle(SwitchToggleStyle(tint: .blue))
                        .scaleEffect(0.7) // 🔥 make toggle smaller
                    
                    Text("Compare to Overall")
                        .font(.caption2) // 🔥 smaller font
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            
            if myData.isEmpty {
                Text("No scan history available")
                    .frame(height: 200)
            } else {
                Chart {
                    ForEach(myData, id: \.date) { item in
                        LineMark(
                            x: .value("Date", item.date),
                            y: .value("Scans", item.count)
                        )
                        .foregroundStyle(by: .value("Series", "My Scans"))
                        .lineStyle(StrokeStyle(lineWidth: 3))
                        
                        PointMark(
                            x: .value("Date", item.date),
                            y: .value("Scans", item.count)
                        )
                        .foregroundStyle(by: .value("Series", "My Scans"))
                        .symbolSize(30)
                    }
                    
                    if showOverallScans {
                        ForEach(overallData, id: \.date) { item in
                            LineMark(
                                x: .value("Date", item.date),
                                y: .value("Scans", item.count)
                            )
                            .foregroundStyle(by: .value("Series", "Overall Scans"))
                            .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
                            
                            PointMark(
                                x: .value("Date", item.date),
                                y: .value("Scans", item.count)
                            )
                            .foregroundStyle(by: .value("Series", "Overall Scans"))
                            .symbolSize(20)
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
                .chartLegend(position: .bottom, alignment: .center, spacing: 16)
                .frame(height: 220)
                .padding()
            }
        }
        .background(Color(.secondarySystemBackground))
    }
}
