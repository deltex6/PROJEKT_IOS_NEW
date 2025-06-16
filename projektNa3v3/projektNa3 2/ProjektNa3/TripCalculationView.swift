import SwiftUI

struct TripCalculationView: View {
    // MARK: – Stany wejściowe i walidacja
    @State private var distance       = ""
    @State private var baseConsumption = ""
    @State private var fuelPrice      = ""
    @State private var passengerCount = ""
    @State private var avgWeight      = ""

    @State private var distanceValid     = true
    @State private var consumptionValid = true
    @State private var priceValid        = true
    @State private var passengersValid   = true
    @State private var weightValid       = true

    @State private var totalFuel: Double?
    @State private var totalCost: Double?

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // — Nagłówek
                Text("Kalkulator kosztów przejazdu")
                    .font(.system(.title, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)

                // — Card z polami
                VStack(spacing: 16) {
                    inputRow(
                        icon: "map",
                        label: "Dystans (km)",
                        text: $distance,
                        placeholder: "np. 120",
                        isValid: $distanceValid,
                        keyboard: .decimalPad,
                        filter: filterDecimal,
                        validate: validatePositiveDouble
                    )

                    inputRow(
                        icon: "speedometer",
                        label: "Spalanie (l/100 km)",
                        text: $baseConsumption,
                        placeholder: "np. 6.5",
                        isValid: $consumptionValid,
                        keyboard: .decimalPad,
                        filter: filterDecimal,
                        validate: validatePositiveDouble
                    )

                    inputRow(
                        icon: "tag",
                        label: "Cena paliwa (zł/l)",
                        text: $fuelPrice,
                        placeholder: "np. 6.00",
                        isValid: $priceValid,
                        keyboard: .decimalPad,
                        filter: filterDecimal,
                        validate: validatePositiveDouble
                    )

                    inputRow(
                        icon: "person.2",
                        label: "Ilość osób",
                        text: $passengerCount,
                        placeholder: "np. 3",
                        isValid: $passengersValid,
                        keyboard: .numberPad,
                        filter: filterInteger,
                        validate: validatePositiveInt
                    )

                    inputRow(
                        icon: "scalemass",
                        label: "Średnia waga osoby (kg)",
                        text: $avgWeight,
                        placeholder: "np. 75",
                        isValid: $weightValid,
                        keyboard: .decimalPad,
                        filter: filterDecimal,
                        validate: validatePositiveDouble
                    )
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)

                // — Przyciski
                Button(action: calculate) {
                    Text("Oblicz koszty")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(GradientButtonStyle())
                .disabled(!formIsValid)

                // — Wyniki
                if let fuel = totalFuel, let cost = totalCost {
                    VStack(spacing: 8) {
                        Label("\(fuel, specifier: "%.2f") L", systemImage: "fuelpump.fill")
                        Label("\(cost, specifier: "%.2f") zł", systemImage: "creditcard.fill")
                    }
                    .font(.title3)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.thickMaterial)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                }
            }
            .padding(20)
        }
        .background(
            LinearGradient(
                colors: [Color.white, Color.blue.opacity(0.1)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }

    // MARK: – Kalkulacje i walidacja

    private var formIsValid: Bool {
        distanceValid && consumptionValid
        && priceValid && passengersValid && weightValid
        && !distance.isEmpty && !baseConsumption.isEmpty
        && !fuelPrice.isEmpty && !passengerCount.isEmpty
        && !avgWeight.isEmpty
    }

    private func calculate() {
        guard
            let dist   = Double(distance),
            let cons   = Double(baseConsumption),
            let price  = Double(fuelPrice),
            let ppl    = Int(passengerCount),
            let avgW   = Double(avgWeight)
        else { return }

        // dodatkowe spalanie na 100 km
        let extraPer100 = (avgW * Double(ppl) * 0.6) / 100
        let totalPer100 = cons + extraPer100

        let needed = (dist / 100) * totalPer100
        totalFuel = needed
        totalCost = needed * price
    }

    private func validatePositiveDouble(_ s: String) -> Bool {
        guard let d = Double(s), d > 0 else { return false }
        return true
    }

    private func validatePositiveInt(_ s: String) -> Bool {
        guard let i = Int(s), i > 0 else { return false }
        return true
    }

    private func filterDecimal(_ s: String) -> String {
        var f = s.filter { "0123456789.".contains($0) }
        let dots = f.filter { $0 == "." }.count
        if dots > 1 {
            var seen = false
            f = f.filter {
                if $0 == "." {
                    if !seen { seen = true; return true }
                    return false
                }
                return true
            }
        }
        return f
    }

    private func filterInteger(_ s: String) -> String {
        s.filter { "0123456789".contains($0) }
    }

    // MARK: – Widok jednego wiersza wejściowego
    @ViewBuilder
    private func inputRow(
        icon: String,
        label: String,
        text: Binding<String>,
        placeholder: String,
        isValid: Binding<Bool>,
        keyboard: UIKeyboardType,
        filter: @escaping (String) -> String,
        validate: @escaping (String) -> Bool
    ) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)

            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)

                TextField(placeholder, text: text)
                    .keyboardType(keyboard)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isValid.wrappedValue ? Color.clear : Color.red, lineWidth: 1)
                    )
                    .onChange(of: text.wrappedValue) { new in
                        let cleaned = filter(new)
                        if cleaned != new { text.wrappedValue = cleaned }
                        isValid.wrappedValue = validate(cleaned)
                    }

                if !isValid.wrappedValue {
                    Text("Niepoprawna wartość")
                        .font(.caption2)
                        .foregroundColor(.red)
                }
            }
        }
    }
}

// MARK: – Styl gradientowego przycisku
struct GradientButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue, Color.purple]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 3)
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}

struct TripCalculationView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TripCalculationView()
        }
    }
}

