import UIKit
import Firebase
import FirebaseAuth
import AVKit
import FirebaseDatabaseInternal
import FSCalendar

class ScanListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, ScanListImageViewControllerDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var refreshButton: UIButton!
    @IBOutlet weak var filterButton: UIButton!
    
    var scans: [[String: String]] = []
    var filteredScans: [[String: String]] = []
    var username: String = ""
    
    private let refreshControl = UIRefreshControl()
    
    enum FilterType {
        case date, partType
    }
    
    var selectedDate: String?
    var selectedPartType: String?
    
    var availableDates: [String] = []
    var availablePartTypes: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
        fetchScansFromFirebase()
    }
    
    func setupUI() {
        refreshButton.layer.cornerRadius = 8
        if let image = UIImage(systemName: "arrow.clockwise.circle") {
            let scaledImage = image.withConfiguration(UIImage.SymbolConfiguration(pointSize: 30, weight: .regular))
            refreshButton.setImage(scaledImage, for: .normal)
        }
        refreshControl.addTarget(self, action: #selector(refreshList), for: .valueChanged)
        tableView.refreshControl = refreshControl
    }
    
    enum CurrentFilter {
        case none
        case dateRange(Date, Date)
    }
    
    var currentFilter: CurrentFilter = .none
    
    func applyCurrentFilter() {
        let formatter = getDateFormatter()

        switch currentFilter {
        case .none:
            filteredScans = scans.filter { scan in
                guard let partType = scan["partType"] else { return false }
                return selectedPartType == nil || selectedPartType == partType
            }

        case .dateRange(let startDate, let endDate):
            filteredScans = scans.filter { scan in
                guard let dateString = scan["date"],
                      let scanDate = formatter.date(from: dateString) else {
                    return false
                }

                let isInDateRange = scanDate >= startDate && scanDate <= endDate
                let matchesPartType = selectedPartType == nil || scan["partType"] == selectedPartType

                return isInDateRange && matchesPartType
            }
        }
    }
    
    func getDateFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }

    
    func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ScanTableViewCell.self, forCellReuseIdentifier: "ScanCell")
        tableView.separatorStyle = .none
        tableView.backgroundColor = .systemGroupedBackground
    }
    
    func fetchScansFromFirebase() {
        scans.removeAll()
        filteredScans.removeAll()
        fetchImagesFromFirebase()
        fetchVideosFromFirebase()
    }
    
    @IBAction func filterButtonTapped(_ sender: UIButton) {
        let alert = UIAlertController(title: "Filter Scans", message: nil, preferredStyle: .actionSheet)

        alert.addAction(UIAlertAction(title: "Filter by Date", style: .default, handler: { _ in
            let calendarVC = CalendarFilterViewController2()
            calendarVC.delegate = self
            self.present(calendarVC, animated: true)
        }))

        alert.addAction(UIAlertAction(title: "Filter by Part Type", style: .default, handler: { _ in
            self.showPartTypeFilter()
        }))
        
        alert.addAction(UIAlertAction(title: "Clear Filters", style: .destructive, handler: { _ in
            self.currentFilter = .none
            self.selectedPartType = nil
            self.applyCurrentFilter()
            self.tableView.reloadData()
        }))

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        present(alert, animated: true)
    }
    
    func showPartTypeFilter() {
        let alert = UIAlertController(title: "Select Part Type", message: nil, preferredStyle: .alert)
        
        for partType in availablePartTypes {
            alert.addAction(UIAlertAction(title: partType, style: .default, handler: { _ in
                self.selectedPartType = partType
                self.applyCurrentFilter()
                self.tableView.reloadData()
            }))
        }

        alert.addAction(UIAlertAction(title: "All Part Types", style: .default, handler: { _ in
            self.selectedPartType = nil
            self.applyCurrentFilter()
            self.tableView.reloadData()
        }))

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    func fetchImagesFromFirebase() {
        guard let user = Auth.auth().currentUser else { return }
        let uid = user.uid
        let databaseRef = Database.database().reference().child("users").child("employees").child(uid)
        databaseRef.observeSingleEvent(of: .value) { snapshot in
            guard let employeeData = snapshot.value as? [String: Any],
                  let imagesData = employeeData["images"] as? [String: [String: Any]] else { return }
            for (folderKey, imageDetails) in imagesData {
                self.scans.append([
                    "folderKey": folderKey,
                    "partType": imageDetails["part_type"] as? String ?? "Unknown Part",
                    "date": imageDetails["date"] as? String ?? "",
                    "url": imageDetails["url"] as? String ?? "",
                    "status": imageDetails["status"] as? String ?? "",
                    "classification": imageDetails["classification"] as? String ?? "",
                    "confidence": imageDetails["confidence"] as? String ?? "",
                    "fileName": imageDetails["fileName"] as? String ?? ""
                ])
            }
            self.applyCurrentFilter()
            self.extractFilterOptions()
            DispatchQueue.main.async {
                self.tableView.reloadData()
                self.refreshControl.endRefreshing()
            }
        }
    }
    
    func fetchVideosFromFirebase() {
        guard let user = Auth.auth().currentUser else { return }
        let uid = user.uid
        let databaseRef = Database.database().reference().child("users").child("employees").child(uid)
        databaseRef.observeSingleEvent(of: .value) { snapshot in
            guard let employeeData = snapshot.value as? [String: Any],
                  let videosData = employeeData["videos"] as? [String: [String: Any]] else { return }
            for (folderKey, videoDetails) in videosData {
                self.scans.append([
                    "folderKey": folderKey,
                    "partType": videoDetails["part_type"] as? String ?? "Unknown Part",
                    "date": videoDetails["date"] as? String ?? "",
                    "url": videoDetails["url"] as? String ?? "",
                    "status": videoDetails["status"] as? String ?? "",
                    "classification": videoDetails["classification"] as? String ?? "",
                    "confidence": videoDetails["confidence"] as? String ?? "",
                    "fileName": videoDetails["fileName"] as? String ?? ""
                ])
            }
            self.applyCurrentFilter()
            self.extractFilterOptions()
            DispatchQueue.main.async {
                self.tableView.reloadData()
                self.refreshControl.endRefreshing()
            }
        }
    }
    
    func extractFilterOptions() {
        availableDates = Array(Set(scans.map { $0["date"] ?? "" })).sorted()
        availablePartTypes = Array(Set(scans.map { $0["partType"] ?? "" })).sorted()
    }
    
    @objc func refreshList() {
        fetchScansFromFirebase()
    }
    
    @IBAction func refreshButtonTapped(_ sender: Any) {
        refreshList()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredScans.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ScanCell", for: indexPath) as! ScanTableViewCell
        let scan = filteredScans[indexPath.row]
        cell.partTypeLabel.text = scan["partType"]
        cell.dateLabel.text = scan["date"]
        cell.statusLabel.text = scan["status"]
        if let confidence = scan["confidence"], let value = Double(confidence) {
            cell.confidenceLabel.text = "\(Int(value * 100))%"
        } else {
            cell.confidenceLabel.text = "N/A"
        }
        cell.statusLabel.textColor = (scan["status"]?.contains("Bad") == true) ? .systemRed : .systemGreen
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedScan = filteredScans[indexPath.row]
        performSegue(withIdentifier: "ScanListImageViewController", sender: selectedScan)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ScanListImageViewController",
           let detailVC = segue.destination as? ScanListImageViewController,
           let selectedScan = sender as? [String: String] {
            detailVC.partType = selectedScan["partType"]
            detailVC.date = selectedScan["date"]
            detailVC.imageURL = selectedScan["url"]
            detailVC.folderKey = selectedScan["folderKey"]
            detailVC.videoURL = selectedScan["videoURL"]
            detailVC.status = selectedScan["status"]
            detailVC.classification = selectedScan["classification"]
            detailVC.confidence = selectedScan["confidence"]
            detailVC.fileName = selectedScan["fileName"]
            detailVC.delegate = self
        }
    }

    func didDeleteScan() {
        reloadScanList()
    }

    func reloadScanList() {
        scans.removeAll()
        filteredScans.removeAll()
        tableView.reloadData()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.fetchScansFromFirebase()
        }
    }
}



class ScanTableViewCell: UITableViewCell {
    let partTypeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .label
        return label
    }()

    let dateLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = .secondaryLabel
        return label
    }()

    let statusLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        return label
    }()

    let confidenceLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = .secondaryLabel
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupUI() {
        contentView.addSubview(partTypeLabel)
        contentView.addSubview(dateLabel)
        contentView.addSubview(statusLabel)
        contentView.addSubview(confidenceLabel)

        partTypeLabel.translatesAutoresizingMaskIntoConstraints = false
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        confidenceLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            partTypeLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            partTypeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            partTypeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            dateLabel.topAnchor.constraint(equalTo: partTypeLabel.bottomAnchor, constant: 4),
            dateLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),

            statusLabel.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 4),
            statusLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),

            confidenceLabel.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 4),
            confidenceLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])

        contentView.backgroundColor = .systemBackground
        contentView.layer.cornerRadius = 8
        contentView.layer.masksToBounds = true
    }
}

class CalendarFilterViewController2: UIViewController {

    weak var delegate: ScanListViewController?
    var selectedRange: (start: Date?, end: Date?) = (nil, nil)

    private lazy var calendar: FSCalendar = {
        let calendar = FSCalendar()
        calendar.translatesAutoresizingMaskIntoConstraints = false
        calendar.delegate = self
        calendar.allowsMultipleSelection = true
        calendar.swipeToChooseGesture.isEnabled = true
        calendar.scope = .month
        calendar.appearance.headerTitleColor = .label
        calendar.appearance.weekdayTextColor = .secondaryLabel
        calendar.appearance.selectionColor = .systemBlue
        calendar.appearance.todayColor = .systemGray5
        return calendar
    }()

    private lazy var infoLabel: UILabel = createLabel(
        text: "Select a start date",
        font: .systemFont(ofSize: 16, weight: .medium),
        backgroundColor: .systemGray6,
        textColor: .systemBlue
    )

    private lazy var applyButton: UIButton = createButton(
        title: "Apply",
        backgroundColor: .systemBlue,
        action: #selector(applyFilter)
    )

    private lazy var clearButton: UIButton = createButton(
        title: "Clear",
        backgroundColor: .systemGray4,
        action: #selector(clearSelection)
    )

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupViews()
    }

    private func setupViews() {
        [calendar, infoLabel, applyButton, clearButton].forEach { view.addSubview($0) }

        NSLayoutConstraint.activate([
            calendar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            calendar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            calendar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            infoLabel.topAnchor.constraint(equalTo: calendar.bottomAnchor, constant: 16),
            infoLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            infoLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            applyButton.topAnchor.constraint(equalTo: infoLabel.bottomAnchor, constant: 16),
            applyButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            applyButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            applyButton.heightAnchor.constraint(equalToConstant: 48),

            clearButton.topAnchor.constraint(equalTo: applyButton.bottomAnchor, constant: 8),
            clearButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            clearButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            clearButton.heightAnchor.constraint(equalToConstant: 48),
            clearButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
    }

    @objc private func applyFilter() {
        if let start = selectedRange.start, let end = selectedRange.end {
            delegate?.currentFilter = .dateRange(start, end)
            delegate?.applyCurrentFilter()
            delegate?.tableView.reloadData()
        }
        dismiss(animated: true)
    }

    @objc private func clearSelection() {
        selectedRange = (nil, nil)
        calendar.selectedDates.forEach { calendar.deselect($0) }
        delegate?.currentFilter = .none
        delegate?.applyCurrentFilter()
        delegate?.tableView.reloadData()
        infoLabel.text = "Select a start date"
    }

    private func createLabel(text: String, font: UIFont, backgroundColor: UIColor, textColor: UIColor) -> UILabel {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = text
        label.font = font
        label.textColor = textColor
        label.textAlignment = .center
        label.numberOfLines = 0
        label.backgroundColor = backgroundColor
        label.layer.cornerRadius = 8
        label.layer.masksToBounds = true
        return label
    }

    private func createButton(title: String, backgroundColor: UIColor, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(title, for: .normal)
        button.backgroundColor = backgroundColor
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }
}

extension CalendarFilterViewController2: FSCalendarDelegate {
    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        if selectedRange.start == nil {
            selectedRange.start = date
            selectedRange.end = nil
            infoLabel.text = "Start date selected. Select an end date."
        } else if let start = selectedRange.start, selectedRange.end == nil {
            if date >= start {
                selectedRange.end = date
                selectRange(from: start, to: date)
                if start == date {
                    infoLabel.text = "Selected: \(formatter.string(from: date))"
                } else {
                    infoLabel.text = "Selected: \(formatter.string(from: start)) → \(formatter.string(from: date))"
                }
            } else {
                calendar.deselect(start)
                selectedRange.start = date
                selectedRange.end = nil
                infoLabel.text = "Start date selected. Select an end date."
            }
        } else {
            calendar.selectedDates.forEach { calendar.deselect($0) }
            selectedRange = (date, nil)
            infoLabel.text = "Start date selected. Select an end date."
        }
    }


    func calendar(_ calendar: FSCalendar, didDeselect date: Date, at monthPosition: FSCalendarMonthPosition) {
        selectedRange = (nil, nil)
        calendar.selectedDates.forEach { calendar.deselect($0) }
        infoLabel.text = "Select a start date"
    }

    private func selectRange(from startDate: Date, to endDate: Date) {
        var currentDate = startDate
        while currentDate <= endDate {
            calendar.select(currentDate)
            currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate)!
        }
    }
}
