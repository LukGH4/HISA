//
//  EmployeeStatsCell.swift
//  HISA
//
//  Created by Luke Hammond on 3/28/25.
//

import UIKit
import FirebaseDatabaseInternal

class EmployeeStatsCell: UITableViewCell {
    
    static let reuseIdentifier = "EmployeeStatsCell"
    
    let partTypeLabel = UILabel()
    let goodCountLabel = UILabel()
    let badCountLabel = UILabel()
    let failureRateLabel = UILabel()
    private let goodProgressView = UIView()
    private let badProgressView = UIView()
    let progressBar = UIProgressView()
    let selectionIndicator = UIView()
    let containerView = UIView()

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
        contentView.addSubview(containerView)

        selectionIndicator.layer.cornerRadius = 12
        selectionIndicator.layer.borderWidth = 2
        selectionIndicator.layer.borderColor = UIColor.systemBlue.cgColor
        selectionIndicator.isHidden = true
        containerView.addSubview(selectionIndicator)

        partTypeLabel.font = UIFont.boldSystemFont(ofSize: 16)
        partTypeLabel.textColor = .darkGray

        goodCountLabel.font = UIFont.systemFont(ofSize: 14)
        goodCountLabel.textColor = .systemGreen

        badCountLabel.font = UIFont.systemFont(ofSize: 14)
        badCountLabel.textColor = .systemRed

        failureRateLabel.font = UIFont.systemFont(ofSize: 14)
        failureRateLabel.textColor = .gray

        goodProgressView.backgroundColor = .systemGreen
        badProgressView.backgroundColor = .systemRed
        progressBar.addSubview(goodProgressView)
        progressBar.addSubview(badProgressView)

        progressBar.layer.cornerRadius = 4
        progressBar.clipsToBounds = true
        progressBar.translatesAutoresizingMaskIntoConstraints = false
        progressBar.heightAnchor.constraint(equalToConstant: 6).isActive = true

        let countsStack = UIStackView(arrangedSubviews: [goodCountLabel, badCountLabel])
        countsStack.axis = .horizontal
        countsStack.spacing = 16
        countsStack.alignment = .center

        let labelsStack = UIStackView(arrangedSubviews: [partTypeLabel, countsStack, failureRateLabel, progressBar])
        labelsStack.axis = .vertical
        labelsStack.spacing = 8
        labelsStack.alignment = .fill
        labelsStack.distribution = .fill

        let mainStack = UIStackView(arrangedSubviews: [labelsStack])
        mainStack.axis = .horizontal
        mainStack.spacing = 16
        mainStack.alignment = .center
        containerView.addSubview(mainStack)

        selectionIndicator.translatesAutoresizingMaskIntoConstraints = false
        containerView.translatesAutoresizingMaskIntoConstraints = false
        mainStack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            selectionIndicator.widthAnchor.constraint(equalToConstant: 24),
            selectionIndicator.heightAnchor.constraint(equalToConstant: 24),
            selectionIndicator.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            selectionIndicator.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),

            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),

            mainStack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            mainStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            mainStack.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            mainStack.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12),

            progressBar.leadingAnchor.constraint(equalTo: labelsStack.leadingAnchor),
            progressBar.trailingAnchor.constraint(equalTo: labelsStack.trailingAnchor)
        ])
    }

    func configure(with partType: String, goodCount: Int, badCount: Int) {
        partTypeLabel.text = partType
        goodCountLabel.text = "Good: \(goodCount)"
        badCountLabel.text = "Bad: \(badCount)"
        
        let total = goodCount + badCount
        let goodRatio = total > 0 ? CGFloat(goodCount) / CGFloat(total) : 0.0
        let failureRate = total > 0 ? (Float(badCount) / Float(total)) * 100 : 0.0
        failureRateLabel.text = "Failure: \(String(format: "%.1f", failureRate))%"
        
        // Update the progress bar views
        goodProgressView.frame = CGRect(x: 0, y: 0, width: progressBar.frame.width * goodRatio, height: progressBar.frame.height)
        badProgressView.frame = CGRect(x: progressBar.frame.width * goodRatio, y: 0, width: progressBar.frame.width * (1 - goodRatio), height: progressBar.frame.height)
    }

    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        selectionIndicator.isHidden = !selected
        selectionIndicator.backgroundColor = selected ? .systemBlue.withAlphaComponent(0.2) : .clear
    }
}
