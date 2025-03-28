import UIKit
import FirebaseDatabaseInternal

class StatsTableViewCell: UITableViewCell {

    static let reuseIdentifier = "StatsTableViewCell"
    let selectionIndicator = UIView()
    let partTypeLabel = UILabel()
    let goodCountLabel = UILabel()
    let badCountLabel = UILabel()
    let failureRateLabel = UILabel()
    let progressBar = UIProgressView()
    let containerView = UIView()
    let editButton = UIButton()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        containerView.layer.cornerRadius = 8
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOpacity = 0.1
        containerView.layer.shadowOffset = CGSize(width: 0, height: 2)
        containerView.layer.shadowRadius = 4
        containerView.backgroundColor = .white

        selectionIndicator.layer.cornerRadius = 12
        selectionIndicator.layer.borderWidth = 2
        selectionIndicator.layer.borderColor = UIColor.systemBlue.cgColor
        selectionIndicator.isHidden = true
        containerView.addSubview(selectionIndicator)

        selectionIndicator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            selectionIndicator.widthAnchor.constraint(equalToConstant: 24),
            selectionIndicator.heightAnchor.constraint(equalToConstant: 24),
            selectionIndicator.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            selectionIndicator.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
        ])

        partTypeLabel.font = UIFont.boldSystemFont(ofSize: 16)
        partTypeLabel.textColor = .darkGray

        goodCountLabel.font = UIFont.systemFont(ofSize: 14)
        goodCountLabel.textColor = .systemGreen

        badCountLabel.font = UIFont.systemFont(ofSize: 14)
        badCountLabel.textColor = .systemRed

        failureRateLabel.font = UIFont.systemFont(ofSize: 14)
        failureRateLabel.textColor = .gray

        progressBar.progressTintColor = .systemGreen
        progressBar.trackTintColor = .lightGray
        progressBar.layer.cornerRadius = 4
        progressBar.clipsToBounds = true
        progressBar.translatesAutoresizingMaskIntoConstraints = false
        progressBar.heightAnchor.constraint(equalToConstant: 6).isActive = true
        

        editButton.setTitle("Edit", for: .normal)
        editButton.setTitleColor(.systemBlue, for: .normal)
        editButton.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        editButton.addTarget(self, action: #selector(editTapped), for: .touchUpInside)

        let countsStack = UIStackView(arrangedSubviews: [goodCountLabel, badCountLabel])
        countsStack.axis = .horizontal
        countsStack.spacing = 16
        countsStack.alignment = .center

        let labelsStack = UIStackView(arrangedSubviews: [partTypeLabel, countsStack, failureRateLabel, progressBar])
        labelsStack.axis = .vertical
        labelsStack.spacing = 8
        labelsStack.alignment = .fill
        labelsStack.distribution = .fill

        let mainStack = UIStackView(arrangedSubviews: [labelsStack, editButton])
        mainStack.axis = .horizontal
        mainStack.spacing = 16
        mainStack.alignment = .center

        containerView.addSubview(mainStack)
        contentView.addSubview(containerView)

        mainStack.translatesAutoresizingMaskIntoConstraints = false
        containerView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            mainStack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            mainStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            mainStack.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            mainStack.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12),
            editButton.widthAnchor.constraint(equalToConstant: 50)
        ])

    }

    func configure(with partType: String, goodCount: Int, badCount: Int) {
        partTypeLabel.text = partType
        goodCountLabel.text = "Good: \(goodCount)"
        badCountLabel.text = "Bad: \(badCount)"
        let total = goodCount + badCount
        let goodRatio = total > 0 ? Float(goodCount) / Float(total) : 0.0
        let failureRate = total > 0 ? (Float(badCount) / Float(total)) * 100 : 0.0
        failureRateLabel.text = "Failure: \(String(format: "%.1f", failureRate))%"
        progressBar.progress = goodRatio
        if goodRatio > 0.5 {
            progressBar.progressTintColor = .systemGreen
            progressBar.trackTintColor = .lightGray
        } else {
            progressBar.progressTintColor = .systemRed
            progressBar.trackTintColor = .systemGray
        }
    }

    @objc func editTapped() {
        let alert = UIAlertController(title: "Set Failure Rate Threshold", message: "Enter a custom threshold for the failure rate for this part type.", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "Enter threshold (0-100)"
            textField.keyboardType = .decimalPad
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Save", style: .default, handler: { _ in
            if let thresholdText = alert.textFields?.first?.text, let threshold = Double(thresholdText), threshold >= 0, threshold <= 100 {
                self.saveCustomThreshold(threshold)
            } else {
                let errorAlert = UIAlertController(title: "Invalid Input", message: "Please enter a valid threshold between 0 and 100.", preferredStyle: .alert)
                errorAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.window?.rootViewController?.present(errorAlert, animated: true, completion: nil)
            }
        }))
        
        self.window?.rootViewController?.present(alert, animated: true, completion: nil)
    }

    private func saveCustomThreshold(_ threshold: Double) {
        let partType = partTypeLabel.text ?? ""
        let partsRef = Database.database().reference().child("parts")
        partsRef.child(partType).observeSingleEvent(of: .value) { snapshot in
            if snapshot.exists() {
                partsRef.child(partType).child("threshold").setValue(threshold) { error, _ in
                    if let error = error {
                        print("Failed to update threshold: \(error.localizedDescription)")
                    } else {
                        print("Threshold for \(partType) updated to: \(threshold)")
                    }
                }
            } else {
                partsRef.child(partType).setValue(["threshold": threshold]) { error, _ in
                    if let error = error {
                        print("Failed to create part with threshold: \(error.localizedDescription)")
                    } else {
                        print("New part \(partType) created with threshold: \(threshold)")
                    }
                }
            }
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        selectionIndicator.isHidden = !selected
        selectionIndicator.backgroundColor = selected ? .systemBlue.withAlphaComponent(0.2) : .clear
    }
}
