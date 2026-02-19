import SwiftUI

struct PriceCalculatorField: View {
    @Binding var text: String
    @Binding var isCalculatorPresented: Bool
    
    var body: some View {
        HStack {
            Spacer()
            HStack(spacing: 6) {
                Text(text.isEmpty ? "可选" : text)
                    .foregroundColor(text.isEmpty ? .secondary : .primary)
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isCalculatorPresented.toggle()
                    }
                } label: {
                    Image(systemName: isCalculatorPresented ? "keyboard.chevron.compact.down" : "plusminus.circle")
                        .font(.subheadline)
                        .foregroundColor(.accentColor)
                }
            }
        }
    }
}

struct InlineCalculatorField: View {
    @Binding var text: String
    
    @State private var showCalculator = false
    
    var body: some View {
        HStack {
            Spacer()
            HStack(spacing: 6) {
                Text(text.isEmpty ? "可选" : text)
                    .foregroundColor(text.isEmpty ? .secondary : .primary)
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showCalculator.toggle()
                    }
                } label: {
                    Image(systemName: showCalculator ? "keyboard.chevron.compact.down" : "plusminus.circle")
                        .font(.subheadline)
                        .foregroundColor(.accentColor)
                }
            }
        }
        .sheet(isPresented: $showCalculator) {
            CalculatorView(text: $text, isPresented: $showCalculator)
                .presentationDetents([.height(380)])
                .presentationDragIndicator(.hidden)
        }
    }
}

struct CalculatorView: View {
    @Binding var text: String
    @Binding var isPresented: Bool
    
    @State private var displayText = "0"
    @State private var previousValue: Double?
    @State private var currentOperation: String?
    @State private var shouldResetDisplay = false
    @State private var expression: String = ""
    
    private let buttonSize: CGFloat = 50
    private let spacing: CGFloat = 4
    
    var body: some View {
        VStack(spacing: 10) {
            displayArea
            buttonGrid
            actionBar
        }
        .padding(16)
        .frame(width: 260)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: .black.opacity(0.25), radius: 16, x: 0, y: 8)
        )
        .onAppear {
            displayText = text.isEmpty ? "0" : text
        }
    }
    
    private var displayArea: some View {
        VStack(alignment: .trailing, spacing: 2) {
            if !expression.isEmpty {
                Text(expression)
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            Text(displayText)
                .font(.system(size: 38, weight: .semibold, design: .monospaced))
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
    
    private var buttonGrid: some View {
        VStack(spacing: spacing) {
            ForEach(buttonRows, id: \.self) { row in
                HStack(spacing: spacing) {
                    ForEach(row, id: \.self) { button in
                        CalculatorButtonView(
                            title: button,
                            size: buttonSize,
                            action: { handleButtonPress(button) }
                        )
                    }
                }
            }
        }
    }
    
    private var actionBar: some View {
        HStack(spacing: 10) {
            Button {
                withAnimation {
                    isPresented = false
                }
            } label: {
                Text("取消")
                    .font(.subheadline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color(.systemGray5))
                    .foregroundColor(.primary)
                    .cornerRadius(8)
            }
            
            Button {
                withAnimation {
                    isPresented = false
                }
            } label: {
                Text("完成")
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
    }
    
    private let buttonRows = [
        ["C", "⌫", "%", "÷"],
        ["7", "8", "9", "×"],
        ["4", "5", "6", "-"],
        ["1", "2", "3", "+"],
        ["±", "0", ".", "="]
    ]
    
    private func handleButtonPress(_ button: String) {
        switch button {
        case "0"..."9":
            handleNumber(button)
        case ".":
            handleDecimal()
        case "+", "-", "×", "÷":
            handleOperation(button)
        case "=":
            handleEquals()
        case "C":
            handleClear()
        case "⌫":
            handleBackspace()
        case "±":
            handleSignToggle()
        case "%":
            handlePercent()
        default:
            break
        }
    }
    
    private func handleNumber(_ num: String) {
        if shouldResetDisplay {
            displayText = num
            shouldResetDisplay = false
        } else {
            if displayText == "0" {
                displayText = num
            } else {
                displayText += num
            }
        }
        syncToText()
    }
    
    private func handleDecimal() {
        if shouldResetDisplay {
            displayText = "0."
            shouldResetDisplay = false
        } else if !displayText.contains(".") {
            displayText += "."
        }
        syncToText()
    }
    
    private func handleOperation(_ op: String) {
        if let current = Double(displayText), let prev = previousValue, let operation = currentOperation {
            expression = formatResult(prev) + " " + operation + " " + formatResult(current)
            let result = calculate(prev, current, operation)
            displayText = formatResult(result)
            previousValue = result
        } else {
            previousValue = Double(displayText)
            expression = displayText
        }
        currentOperation = op
        shouldResetDisplay = true
        syncToText()
    }
    
    private func handleEquals() {
        guard let current = Double(displayText),
              let prev = previousValue,
              let operation = currentOperation else {
            return
        }
        
        expression = formatResult(prev) + " " + operation + " " + formatResult(current)
        let result = calculate(prev, current, operation)
        displayText = formatResult(result)
        previousValue = nil
        currentOperation = nil
        shouldResetDisplay = true
        syncToText()
    }
    
    private func handleClear() {
        displayText = "0"
        expression = ""
        previousValue = nil
        currentOperation = nil
        shouldResetDisplay = false
        syncToText()
    }
    
    private func handleBackspace() {
        if displayText.count > 1 {
            displayText.removeLast()
        } else {
            displayText = "0"
        }
        syncToText()
    }
    
    private func handleSignToggle() {
        if displayText != "0" {
            if displayText.hasPrefix("-") {
                displayText.removeFirst()
            } else {
                displayText = "-" + displayText
            }
        }
        syncToText()
    }
    
    private func handlePercent() {
        if let value = Double(displayText) {
            displayText = formatResult(value / 100)
        }
        syncToText()
    }
    
    private func syncToText() {
        if let value = Double(displayText) {
            if value.truncatingRemainder(dividingBy: 1) == 0 {
                text = String(format: "%.0f", value)
            } else {
                text = String(value)
            }
        }
    }
    
    private func calculate(_ a: Double, _ b: Double, _ operation: String) -> Double {
        switch operation {
        case "+": return a + b
        case "-": return a - b
        case "×": return a * b
        case "÷": return b != 0 ? a / b : 0
        default: return b
        }
    }
    
    private func formatResult(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", value)
        } else {
            let formatted = String(value)
            return formatted.count > 10 ? String(format: "%.4f", value) : formatted
        }
    }
}

struct CalculatorButtonView: View {
    let title: String
    let size: CGFloat
    let action: () -> Void
    
    private var isOperator: Bool {
        ["+", "-", "×", "÷", "=", "%"].contains(title)
    }
    
    private var isFunction: Bool {
        ["C", "⌫", "±"].contains(title)
    }
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .frame(width: size, height: size)
                .background(backgroundColor)
                .foregroundColor(.white)
                .cornerRadius(size / 2)
        }
    }
    
    private var backgroundColor: Color {
        if isOperator {
            return .orange
        } else if isFunction {
            return .gray.opacity(0.5)
        } else {
            return .gray.opacity(0.3)
        }
    }
}
