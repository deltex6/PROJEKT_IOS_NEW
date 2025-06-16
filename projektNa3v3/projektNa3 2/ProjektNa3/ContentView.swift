import SwiftUI

struct MainView: View {
    // MARK: – Dane samochodu
    @AppStorage("carName") private var carName = "VW Golf"
    @AppStorage("tankCapacity") private var tankCapacity: Double = 50.0

    // MARK: – Stany edycji i interakcji
    @State private var isEditingCar     = false
    @State private var draftCarName     = ""
    @State private var draftTankCapacity = ""
    @State private var iconExpanded     = false

    var body: some View {
        NavigationView {
            ZStack {
                // – Tło gradientowe
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.15), Color.white]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    // – Duża ikonka samochodu
                    Image(systemName: "car.fill")
                        .font(.system(size: 72, weight: .semibold))
                        .foregroundColor(.blue)
                        .scaleEffect(iconExpanded ? 1.3 : 1.0)
                        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: iconExpanded)
                        .onTapGesture {
                            iconExpanded.toggle()
                        }
                        .padding(.top, 16)

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 24) {
                            // – Karty nawigacyjne
                            HomeCard(
                                icon: "fuelpump.fill",
                                title: "Tankowania",
                                color: .blue,
                                destination: FuelEntriesView()
                            )

                            HomeCard(
                                icon: "map.fill",
                                title: "Kalkulator trasy",
                                color: .green,
                                destination: TripCalculationView()
                            )

                            HomeCard(
                                icon: "chart.bar.fill",
                                title: "Statystyki",
                                color: .orange,
                                destination: StatsView()
                            )
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 16)
                    }

                    Divider()
                        .padding(.vertical, 8)

                    // – Informacje o samochodzie
                    CarInfoView(carName: carName, tankCapacity: tankCapacity)
                        .padding(.horizontal)
                        .padding(.bottom, 16)
                        .onLongPressGesture {
                            draftCarName = carName
                            draftTankCapacity = String(format: "%.0f", tankCapacity)
                            isEditingCar = true
                        }
                }
            }
            .navigationTitle("Aplikacja paliwowa")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $isEditingCar) {
                EditCarSheet(
                    draftName: $draftCarName,
                    draftCapacity: $draftTankCapacity,
                    isPresented: $isEditingCar,
                    saveAction: {
                        let nameTrimmed = draftCarName.trimmingCharacters(in: .whitespaces)
                        if let cap = Double(draftTankCapacity), !nameTrimmed.isEmpty {
                            carName = nameTrimmed
                            tankCapacity = cap
                            isEditingCar = false
                        }
                    }
                )
            }
        }
    }
}

// MARK: – Pojedyncza karta nawigacji
struct HomeCard<Destination: View>: View {
    let icon: String
    let title: String
    let color: Color
    let destination: Destination

    var body: some View {
        NavigationLink(destination: destination) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(color)
                        .frame(width: 48, height: 48)
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white)
                }

                Text(title)
                    .font(.system(.title3, design: .rounded))
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        }
    }
}

// MARK: – Widok informacji o samochodzie
struct CarInfoView: View {
    let carName: String
    let tankCapacity: Double

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Label("Samochód", systemImage: "car.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(carName)
                    .font(.headline)
                    .fontWeight(.medium)
            }

            Spacer()

            VStack(alignment: .leading, spacing: 4) {
                Label("Zbiornik", systemImage: "gauge")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(Int(tankCapacity)) L")
                    .font(.headline)
                    .fontWeight(.medium)
            }
        }
        .padding()
        .background(.thickMaterial)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

// MARK: – Sheet do edycji samochodu
struct EditCarSheet: View {
    @Binding var draftName: String
    @Binding var draftCapacity: String
    @Binding var isPresented: Bool
    let saveAction: () -> Void

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Nazwa samochodu")) {
                    TextField("Nazwa samochodu", text: $draftName)
                }
                Section(header: Text("Pojemność zbiornika (L)")) {
                    TextField("Liczba litrów", text: $draftCapacity)
                        .keyboardType(.decimalPad)
                        .onChange(of: draftCapacity) { newValue in
                            var filtered = newValue.filter { "0123456789.".contains($0) }
                            let dots = filtered.filter { $0 == "." }.count
                            if dots > 1 {
                                var seen = false
                                filtered = filtered.filter {
                                    if $0 == "." {
                                        if !seen { seen = true; return true }
                                        return false
                                    }
                                    return true
                                }
                            }
                            if filtered != newValue {
                                draftCapacity = filtered
                            }
                        }
                }
            }
            .navigationTitle("Edytuj auto")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Anuluj") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Zapisz", action: saveAction)
                }
            }
        }
    }
}

// MARK: – Preview
struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}

