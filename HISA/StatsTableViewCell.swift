import UIKit
import FirebaseDatabaseInternal

class StatsTableViewCell: UITableViewCell {
    
    static let reuseIdentifier = "StatsTableViewCell"
    
    let partTypeLabel = UILabel()
    let goodCountLabel = UILabel()
    let badCountLabel = UILabel()
    let failureRateLabel = UILabel()
    let selectionIndicator = UIView()
    let editButton = UIButton()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        selectionIndicator.layer.cornerRadius = 12
        selectionIndicator.layer.borderWidth = 2
        selectionIndicator.layer.borderColor = UIColor.systemBlue.cgColor
        selectionIndicator.isHidden = true
        
        partTypeLabel.font = UIFont.boldSystemFont(ofSize: 16)
        failureRateLabel.font = UIFont.systemFont(ofSize: 14)
        goodCountLabel.font = UIFont.systemFont(ofSize: 14)
        badCountLabel.font = UIFont.systemFont(ofSize: 14)
        
        editButton.setTitle("Edit", for: .normal)
        editButton.setTitleColor(.systemBlue, for: .normal)
        editButton.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        editButton.addTarget(self, action: #selector(editTapped), for: .touchUpInside)
        
        let labelsStack = UIStackView(arrangedSubviews: [partTypeLabel, goodCountLabel, badCountLabel, failureRateLabel])
        labelsStack.axis = .horizontal
        labelsStack.spacing = 10
        labelsStack.alignment = .center
        
        let mainStack = UIStackView(arrangedSubviews: [selectionIndicator, labelsStack, editButton])
        mainStack.spacing = 8
        mainStack.alignment = .center
        
        contentView.addSubview(mainStack)
        
        selectionIndicator.translatesAutoresizingMaskIntoConstraints = false
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            selectionIndicator.widthAnchor.constraint(equalToConstant: 24),
            selectionIndicator.heightAnchor.constraint(equalToConstant: 24),
            
            mainStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            mainStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            mainStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            mainStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
    }
    
    func configure(with partType: String, goodCount: Int, badCount: Int, isSelected: Bool = false) {
        partTypeLabel.text = partType
        goodCountLabel.text = "Good: \(goodCount)"
        badCountLabel.text = "Bad: \(badCount)"
        
        let total = goodCount + badCount
        let failureRate = total > 0 ? (Double(badCount) / Double(total)) * 100 : 0.0
        failureRateLabel.text = "Failure: \(String(format: "%.1f", failureRate))%"
        failureRateLabel.textColor = failureRate > 20 ? .red : .green
        
        selectionIndicator.isHidden = !isSelected
        selectionIndicator.backgroundColor = isSelected ? .systemBlue.withAlphaComponent(0.2) : .clear
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
