import UIKit

class StatsTableViewCell: UITableViewCell {
    
    static let reuseIdentifier = "StatsTableViewCell"
    
    let partTypeLabel = UILabel()
    let goodCountLabel = UILabel()
    let badCountLabel = UILabel()
    let failureRateLabel = UILabel()
    let selectionIndicator = UIView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        // Selection indicator
        selectionIndicator.layer.cornerRadius = 12
        selectionIndicator.layer.borderWidth = 2
        selectionIndicator.layer.borderColor = UIColor.systemBlue.cgColor
        selectionIndicator.isHidden = true
        
        // Labels setup
        partTypeLabel.font = UIFont.boldSystemFont(ofSize: 16)
        failureRateLabel.font = UIFont.systemFont(ofSize: 14)
        goodCountLabel.font = UIFont.systemFont(ofSize: 14)
        badCountLabel.font = UIFont.systemFont(ofSize: 14)
        
        let labelsStack = UIStackView(arrangedSubviews: [partTypeLabel, goodCountLabel, badCountLabel, failureRateLabel])
        labelsStack.axis = .horizontal
        labelsStack.spacing = 10
        labelsStack.alignment = .center
        
        let mainStack = UIStackView(arrangedSubviews: [selectionIndicator, labelsStack])
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
        
        // Update selection UI
        selectionIndicator.isHidden = !isSelected
        selectionIndicator.backgroundColor = isSelected ? .systemBlue.withAlphaComponent(0.2) : .clear
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        selectionIndicator.isHidden = !selected
        selectionIndicator.backgroundColor = selected ? .systemBlue.withAlphaComponent(0.2) : .clear
    }
}
