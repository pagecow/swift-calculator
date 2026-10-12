//
//  ContentView.swift
//  SwiftCalculator
//
//  The screen: a big display on top of a 4-column keypad.
//

import SwiftUI

struct ContentView: View {
    /// The calculator's state. `@State` owns it for the lifetime of the view.
    @State private var calculator = CalculatorEngine()

    var body: some View {
        VStack(spacing: 16) {
            display
            keypad
        }
        .padding(20)
        .background(Color(uiColor: .systemBackground))
    }

    // MARK: - Display

    /// The large right-aligned number at the top.
    private var display: some View {
        Text(calculator.display)
            .font(.system(size: 76, weight: .light, design: .rounded))
            .lineLimit(1)
            .minimumScaleFactor(0.4)                 // long numbers shrink instead of clipping
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            .contentTransition(.numericText())
            .animation(.snappy(duration: 0.15), value: calculator.display)
    }

    // MARK: - Keypad

    /// Rows of keys. `Grid` keeps every column the same width, and
    /// `gridCellColumns(2)` lets the "0" key span two of them.
    private var keypad: some View {
        Grid(horizontalSpacing: 12, verticalSpacing: 12) {
            GridRow {
                key("AC", style: .function) { calculator.clear() }
                key("±", style: .function) { calculator.toggleSign() }
                key("%", style: .function) { calculator.percent() }
                operationKey(.divide)
            }
            GridRow {
                digitKey(7)
                digitKey(8)
                digitKey(9)
                operationKey(.multiply)
            }
            GridRow {
                digitKey(4)
                digitKey(5)
                digitKey(6)
                operationKey(.subtract)
            }
            GridRow {
                digitKey(1)
                digitKey(2)
                digitKey(3)
                operationKey(.add)
            }
            GridRow {
                digitKey(0).gridCellColumns(2)
                key(".", style: .digit) { calculator.decimal() }
                key("=", style: .operation) { calculator.equals() }
            }
        }
    }

    // MARK: - Key builders

    private func key(
        _ title: String,
        style: KeyButton.Style,
        action: @escaping () -> Void
    ) -> some View {
        KeyButton(title: title, style: style, isSelected: false, action: action)
    }

    private func digitKey(_ digit: Int) -> some View {
        key("\(digit)", style: .digit) { calculator.input(digit) }
    }

    /// An operation key, highlighted while it is the pending operation.
    private func operationKey(_ operation: CalculatorEngine.Operation) -> some View {
        KeyButton(
            title: operation.symbol,
            style: .operation,
            isSelected: calculator.pendingOperation == operation
        ) {
            calculator.setOperation(operation)
        }
    }
}

// MARK: - A single key

/// One round button on the keypad.
private struct KeyButton: View {

    enum Style {
        case digit
        case function
        case operation
    }

    let title: String
    let style: Style
    var isSelected: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 32, weight: .medium, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .foregroundStyle(foregroundColor)
                .frame(maxWidth: .infinity)
                .frame(height: 72)
                .background(backgroundColor, in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .animation(.snappy(duration: 0.2), value: isSelected)
    }

    private var foregroundColor: Color {
        switch style {
        case .digit:
            return isSelected ? .white : .primary
        case .function:
            return .primary
        case .operation:
            return isSelected ? .orange : .white
        }
    }

    private var backgroundColor: Color {
        switch style {
        case .digit:
            return Color(uiColor: .secondarySystemBackground)
        case .function:
            return Color(uiColor: .tertiarySystemBackground)
        case .operation:
            return isSelected ? .white : .orange
        }
    }
}

#Preview {
    ContentView()
}
