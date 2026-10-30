//
//  StoriesProgressBar.swift
//  Example
//

import UIKit

final class StoriesProgressBar: UIView {
    private var tracks: [UIView] = []
    private var fills: [UIView] = []
    private var widthConstraints: [NSLayoutConstraint] = []
    private var activeIndex: Int = 0
    private let stack = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        stack.axis = .horizontal
        stack.spacing = 4
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    func configure(segmentCount: Int) {
        tracks.forEach { $0.removeFromSuperview() }
        tracks.removeAll()
        fills.removeAll()
        widthConstraints.removeAll()

        for _ in 0..<segmentCount {
            let track = UIView()
            track.backgroundColor = UIColor.white.withAlphaComponent(0.3)
            track.layer.cornerRadius = 1.5
            track.clipsToBounds = true
            track.translatesAutoresizingMaskIntoConstraints = false

            let fill = UIView()
            fill.backgroundColor = .white
            fill.translatesAutoresizingMaskIntoConstraints = false
            track.addSubview(fill)

            let widthConstraint = fill.widthAnchor.constraint(equalToConstant: 0)
            NSLayoutConstraint.activate([
                fill.leadingAnchor.constraint(equalTo: track.leadingAnchor),
                fill.topAnchor.constraint(equalTo: track.topAnchor),
                fill.bottomAnchor.constraint(equalTo: track.bottomAnchor),
                widthConstraint
            ])

            stack.addArrangedSubview(track)
            tracks.append(track)
            fills.append(fill)
            widthConstraints.append(widthConstraint)
        }
    }

    func setActiveSegment(_ index: Int) {
        activeIndex = index
        for i in fills.indices {
            replaceWidth(at: i, ratio: i < index ? 1 : 0)
        }
    }

    func setProgress(_ ratio: CGFloat) {
        guard fills.indices.contains(activeIndex) else { return }
        replaceWidth(at: activeIndex, ratio: max(0, min(1, ratio)))
    }

    func fillActiveSegment() {
        setProgress(1)
    }

    private func replaceWidth(at index: Int, ratio: CGFloat) {
        widthConstraints[index].isActive = false
        let fill = fills[index]
        let track = tracks[index]
        let newConstraint: NSLayoutConstraint
        if ratio <= 0 {
            newConstraint = fill.widthAnchor.constraint(equalToConstant: 0)
        } else if ratio >= 1 {
            newConstraint = fill.widthAnchor.constraint(equalTo: track.widthAnchor)
        } else {
            newConstraint = fill.widthAnchor.constraint(equalTo: track.widthAnchor, multiplier: ratio)
        }
        newConstraint.isActive = true
        widthConstraints[index] = newConstraint
    }
}
