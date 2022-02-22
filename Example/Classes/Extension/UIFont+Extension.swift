//
//  UIFont+Extension.swift
//  Example
//
//  Created by Slience on 2021/1/13.
//

import UIKit

extension UIFont {
    
    static func regularPingFang(ofSize size: CGFloat) -> UIFont {
        let font = UIFont(name: Lato.regular.fontName, size: size)
        return font ?? UIFont.systemFont(ofSize: size)
    }
    
    static func mediumPingFang(ofSize size: CGFloat) -> UIFont {
        let font = UIFont(name: Lato.bold.fontName, size: size)
        return font ?? UIFont.systemFont(ofSize: size)
    }
    
    static func semiboldPingFang(ofSize size: CGFloat) -> UIFont {
        let font = UIFont(name: Lato.lightItalic.fontName, size: size)
        return font ?? UIFont.systemFont(ofSize: size)
    }
}

// MARK: -

protocol CustomFont {
    
    var fontName: String { get }
}

extension UIFont {
    
    enum Lato: String, CustomFont {
        case regular
        case italic
        case hairline
        case hairlineItalic
        case light
        case lightItalic
        case bold
        case boldItalic
        case black
        case blackItalic
        
        var fontName: String {
            return "Lato-\(rawValue.capitalized)"
        }
    }
    
    enum AvenirNext: String, CustomFont {
        case bold
        
        var fontName: String {
            return "AvenirNext-\(rawValue.capitalized)"
        }
    }
    
    static func font(_ customFont: CustomFont, size: CGFloat) -> UIFont {
        return UIFont(name: customFont.fontName, size: size) ?? .systemFont(ofSize: size)
    }
}

// MARK: -

fileprivate protocol FontConvertible {
    
    func convert() -> UIFont
}

// MARK: - Lato

extension Lato: FontConvertible {
    
    func convert() -> UIFont {
        return .font(font, size: size)
    }
}

struct Lato {
    
    private let font: UIFont.Lato
    
    private let size: CGFloat
    
    private init(font: UIFont.Lato, size: CGFloat) {
        self.font = font
        self.size = size
    }
}

extension Lato {
    
    static var regular: Lato {
        return .init(font: .regular, size: 12)
    }
    
    static var bold: Lato {
        return .init(font: .bold, size: 12)
    }
    
    static var boldItalic: Lato {
        return .init(font: .boldItalic, size: 12)
    }
}

extension Lato {
    
    var largeTitle: UIFont {
        return Lato(font: font, size: 36).convert()
    }
    
    var title1: UIFont {
        return Lato(font: font, size: 30).convert()
    }
    
    var title2: UIFont {
        return Lato(font: font, size: 24).convert()
    }
    
    var title3: UIFont {
        return Lato(font: font, size: 20).convert()
    }
    
    var largeHeadline: UIFont {
        return Lato(font: font, size: 18).convert()
    }
    
    var headline: UIFont {
        return Lato(font: font, size: 16).convert()
    }
    
    var body: UIFont {
        return Lato(font: font, size: 14).convert()
    }
    
    var caption: UIFont {
        return Lato(font: font, size: 12).convert()
    }
    
    var normal: UIFont {
        return Lato(font: font, size: 10).convert()
    }
}

// MARK: - AvenirNext-Bold

extension AvenirNext: FontConvertible {
    
    func convert() -> UIFont {
        return .font(font, size: size)
    }
}

struct AvenirNext {
    
    private let font: UIFont.AvenirNext
    
    private let size: CGFloat
    
    private init(font: UIFont.AvenirNext, size: CGFloat) {
        self.font = font
        self.size = size
    }
}

/// Extensions for the weight of font.
extension AvenirNext {
    
    static var bold: AvenirNext {
        return .init(font: .bold, size: 12)
    }
}

/// Extensions for the size of font.
extension AvenirNext {
    
    var title: UIFont {
        return AvenirNext(font: font, size: 24).convert()
    }
}
