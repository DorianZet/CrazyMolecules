//
//  BottomControlsStackView.swift
//  MoleculesGame
//
//  Created by Mateusz Zacharski on 15/02/2021.
//

import UIKit

func createButton(bgColor color: UIColor) -> UIButton {
    let button = UIButton(type: .system)
    button.backgroundColor = color
    button.layer.cornerRadius = 10
    button.setTitle(">>", for: .normal)
    button.setTitleColor(.black, for: .normal)
    button.titleLabel?.font = UIFont.systemFont(ofSize: 22, weight: .bold)
    button.layer.borderWidth = 3
    button.layer.borderColor = UIColor.white.cgColor
    return button
}

class BottomControlsStackView: UIStackView {
    var redButton: UIButton = createButton(bgColor: .systemRed) // the same way we can create green and yellow button.
    var greenButton: UIButton = createButton(bgColor: .systemGreen)
    var yellowButton: UIButton = createButton(bgColor: .systemYellow)
    
    
    lazy var bottomStackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.distribution = .fillEqually
        sv.spacing = 16
        [redButton, yellowButton, greenButton].forEach { (button) in
            sv.addArrangedSubview(button)
        }
        return sv
    }()
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)

        distribution = .fillEqually
        axis = .horizontal
        spacing = 16
        
        [redButton, yellowButton, greenButton].forEach { (button) in
            self.addArrangedSubview(button)
        }
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
