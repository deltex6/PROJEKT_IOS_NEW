import SwiftUI
import CoreData

struct FuelEntriesView: View {
    // MARK: – Core Data
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \FuelEntry.date, ascending: false)]
    ) private var fuelEntries: FetchedResults<FuelEntry>

    // MARK: – Pola formularza
    @State private var amountText = ""
    @State private var mileageText = ""
    @State private var showingAlert = false

    var body: some View {
        ZStack {
            // – podkład gradientowy
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.2), Color.white]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // — Nagłówek z dużą ikoną
                Image(systemName: "fuelpump.fill")
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue, Color.green]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 3)
                    .padding(.top, 20)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // — Formularz dodawania wpisu
                        VStack(spacing: 16) {
                            Text("Dodaj Tankowanie")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)

                            HStack(spacing: 12) {
                                Image(systemName: "fuelpump")
                                    .foregroundColor(.blue)
                                TextField("Ilość paliwa (l)", text: $amountText)
                                    .keyboardType(.decimalPad)
                            }
                            .padding()
                            .background(.ultraThinMaterial)
                            .cornerRadius(12)

                            HStack(spacing: 12) {
                                Image(systemName: "gauge")
                                    .foregroundColor(.green)
                                TextField("Przebieg (km)", text: $mileageText)
                                    .keyboardType(.decimalPad)
                            }
                            .padding()
                            .background(.ultraThinMaterial)
                            .cornerRadius(12)

                            Button("Dodaj") {
                                if let amount = Double(amountText),
                                   let mileage = Double(mileageText),
                                   amount > 0, mileage > 0 {
                                    addFuelEntry(amount: amount, mileage: mileage)
                                    amountText = ""
                                    mileageText = ""
                                } else {
                                    showingAlert = true
                                }
                            }
                            .buttonStyle(GradientButtonStyle())
                        }
                        .padding()
                        .background(.thickMaterial)
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)

                        // — Lista wpisów
                        LazyVStack(spacing: 16) {
                            ForEach(fuelEntries) { entry in
                                FuelEntryRow(entry: entry, onDelete: {
                                    deleteEntry(entry)
                                })
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 20)
                }
            }
        }
        .navigationTitle("Tankowania")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Błędne dane", isPresented: $showingAlert) {
            Button("OK", role: .cancel) {}
        }
    }

    // MARK: – Core Data ops
    private func addFuelEntry(amount: Double, mileage: Double) {
        let newEntry = FuelEntry(context: viewContext)
        newEntry.id = UUID()
        newEntry.date = Date()
        newEntry.amount = amount
        newEntry.mileage = mileage
        saveContext()
    }

    private func deleteEntry(_ entry: FuelEntry) {
        viewContext.delete(entry)
        saveContext()
    }

    private func saveContext() {
        do { try viewContext.save() }
        catch { print(error.localizedDescription) }
    }
}

// MARK: – Pojedynczy wiersz z wpisem
struct FuelEntryRow: View {
    var entry: FuelEntry
    var onDelete: () -> Void

    @State private var offset: CGFloat = 0
    private let threshold: CGFloat = 80

    var body: some View {
        ZStack(alignment: .trailing) {
            // — ukryty przycisk „Usuń”
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.red)
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "fuelpump.fill")
                            .foregroundColor(.blue)
                        Text("\(entry.amount, specifier: "%.2f") L")
                            .font(.subheadline).fontWeight(.semibold)
                    }
                    HStack {
                        Image(systemName: "gauge")
                            .foregroundColor(.green)
                        Text("\(entry.mileage, specifier: "%.0f") km")
                            .font(.subheadline)
                    }
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(.secondary)
                        Text(entry.date!, formatter: itemFormatter)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                Image(systemName: "trash.fill")
                    .foregroundColor(.white)
                    .opacity(offset < -threshold ? 1 : 0)
                    .padding(.trailing, 20)
            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(12)
            .offset(x: offset)
            .gesture(
                DragGesture()
                    .onChanged { g in
                        if g.translation.width < 0 {
                            offset = g.translation.width
                        }
                    }
                    .onEnded { g in
                        withAnimation(.spring()) {
                            if g.translation.width < -threshold {
                                offset = -120
                            } else {
                                offset = 0
                            }
                        }
                    }
            )
        }
        .frame(height: 100)
        .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
    }
}

//// MARK: – Gradientowy ButtonStyle
//struct GradientButtonStyle: ButtonStyle {
//    func makeBody(configuration: Configuration) -> some View {
//        configuration.label
//            .font(.headline)
//            .frame(maxWidth: .infinity)
//            .padding()
//            .background(
//                LinearGradient(
//                    gradient: Gradient(colors: [Color.blue, Color.purple]),
//                    startPoint: .leading,
//                    endPoint: .trailing
//                )
//            )
//            .foregroundColor(.white)
//            .cornerRadius(12)
//            .shadow(color: .black.opacity(0.15), radius: 5, x: 0, y: 3)
//            .scaleEffect(configuration.isPressed ? 0.96 : 1)
//            .opacity(configuration.isPressed ? 0.8 : 1)
//    }
//}

// MARK: – Formatter daty
private let itemFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateStyle = .short
    f.timeStyle = .short
    return f
}()

// MARK: – Preview
struct FuelEntriesView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            FuelEntriesView()
                .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        }
    }
}

