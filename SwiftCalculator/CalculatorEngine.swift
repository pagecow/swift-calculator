//
//  CalculatorEngine.swift
//  SwiftCalculator
//
//  The calculator's brain. It holds no SwiftUI views, so the whole thing can
//  be reasoned about (and tested) as plain number logic.
//

import Foundation
import Observation

/// The state machine behind the keypad.
///
/// The `@Observable` macro tells SwiftUI to redraw any view that reads one of
/// these properties whenever it changes.
@Observable
final class CalculatorEngine {

    /// The four operations the keypad offers.
    enum Operation: String, CaseIterable {
        case add = "+"
        case subtract = "−"
        case multiply = "×"
        case divide = "÷"

        /// The symbol shown on the key.
        var symbol: String { rawValue }

        /// Combines the two numbers. Dividing by zero gives `nan`, which the
        /// display turns into "Error" for the user.
        func apply(_ lhs: Double, _ rhs: Double) -> Double {
            switch self {
            case .add:      return lhs + rhs
            case .subtract: return lhs - rhs
            case .multiply: return lhs * rhs
            case .divide:   return rhs == 0 ? .nan : lhs / rhs
            }
        }
    }

    // MARK: - State

    /// The value on screen whenever the user is not mid-way through typing.
    private var currentValue = 0.0

    /// The digits being typed right now, or `nil` when the display is showing
    /// a value the calculator produced (a result, or a number being reused).
    private var typedText: String?

    /// The number waiting on the left of the pending operation.
    private var leftOperand: Double?

    /// The operation waiting for its right-hand number, if any.
    private(set) var pendingOperation: Operation?

    /// What the display shows. Recomputed automatically as state changes.
    var display: String {
        typedText ?? Self.format(currentValue)
    }

    /// The number the display currently stands for.
    private var displayValue: Double {
        guard let typedText else { return currentValue }
        // "0." and "12." are valid in-progress entries; drop the dot to parse.
        return Double(typedText) ?? Double(typedText.dropLast()) ?? currentValue
    }

    // MARK: - Input

    /// Appends a digit to the number being typed, or starts a new number.
    func input(_ digit: Int) {
        if let text = typedText {
            guard text.filter(\.isNumber).count < 9 else { return }   // keep it readable
            typedText = (text == "0") ? String(digit) : text + String(digit)
        } else {
            typedText = String(digit)
        }
    }

    /// Adds a decimal point to the number being typed.
    func decimal() {
        guard let text = typedText else {
            typedText = "0."
            return
        }
        guard !text.contains(".") else { return }
        typedText = text + "."
    }

    /// Flips the sign of the number on screen.
    func toggleSign() {
        guard let text = typedText else {
            currentValue = -currentValue
            return
        }
        guard text != "0" else { return }                            // never show "-0"
        typedText = text.hasPrefix("-") ? String(text.dropFirst()) : "-" + text
    }

    /// Turns the number on screen into a percentage.
    func percent() {
        if let pending = pendingOperation, let left = leftOperand,
           pending == .add || pending == .subtract {
            // 200 + 10 % means "10 percent of 200", i.e. 20.
            currentValue = left * displayValue / 100
        } else {
            currentValue = displayValue / 100
        }
        typedText = nil
    }

    /// Stores the left-hand number and remembers what to do with the next one.
    func setOperation(_ operation: Operation) {
        // Chaining (2 + 3 +) settles the previous operation first.
        if let pending = pendingOperation, let left = leftOperand, typedText != nil {
            currentValue = pending.apply(left, displayValue)
        } else {
            currentValue = displayValue
        }
        leftOperand = currentValue
        typedText = nil
        pendingOperation = operation
    }

    /// Works out the pending operation and shows the answer.
    func equals() {
        guard let pending = pendingOperation, let left = leftOperand else { return }
        currentValue = pending.apply(left, displayValue)
        typedText = nil
        leftOperand = nil
        pendingOperation = nil
    }

    /// Resets everything back to a fresh "0".
    func clear() {
        currentValue = 0
        typedText = nil
        leftOperand = nil
        pendingOperation = nil
    }

    // MARK: - Formatting

    private static let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 8
        return formatter
    }()

    /// Renders a number with thousands separators, 1,234.5 style.
    private static func format(_ value: Double) -> String {
        guard value.isFinite else { return "Error" }
        return formatter.string(from: NSNumber(value: value)) ?? "0"
    }
}
