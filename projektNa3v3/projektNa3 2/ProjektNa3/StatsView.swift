import SwiftUI
import Charts

struct MonthlyFuel: Identifiable {
    let id = UUID()
    let month: String
    let total: Double
}

struct MileagePoint: Identifiable {
    let id = UUID()
    let date: Date
    let cumulativeMileage: Double
}

struct StatsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \FuelEntry.date, ascending: true)]
    )
    private var fuelEntries: FetchedResults<FuelEntry>
    
    // Łączna liczba tankowań
    var totalEntries: Int {
        fuelEntries.count
    }
    
    // Łączna ilość zatankowanego paliwa
    var totalFuel: Double {
        fuelEntries.reduce(0) { $0 + $1.amount }
    }
    
    // Średnia ilość paliwa na tankowanie
    var averageFuel: Double {
        if totalEntries > 0 {
            return totalFuel / Double(totalEntries)
        } else {
            return 0
        }
    }
    
    // Obliczenie średniego zużycia: przyjmujemy, że zużycie liczymy na podstawie różnicy przebiegów
    // i całej zatankowanej ilości paliwa (pomijamy pierwszy wpis, który nie ma "poprzendzianego" przebiegu).
    // Uwaga: Zależności w sposobie obliczania mogą być zmienione w zależności od sposobu tankowania.
    var averageConsumption: Double? {
        if fuelEntries.count > 1,
           let first = fuelEntries.first,
           let last = fuelEntries.last,
           last.mileage > first.mileage {
            // Przyjmujemy, że paliwo z pierwszego tankowania nie jest liczone, więc dzielimy sumę paliwa poza pierwszym wpisem
            let fuelForConsumption = fuelEntries.dropFirst().reduce(0) { $0 + $1.amount }
            let distance = last.mileage - first.mileage
            // Średnie zużycie w l/100km
            return (fuelForConsumption / distance) * 100
        }
        return nil
    }
    
    // Wykresy - dane miesięczne
    var monthlyData: [MonthlyFuel] {
        let grouped = Dictionary(grouping: fuelEntries) { entry in
            let date = entry.date ?? Date()
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM"
            return formatter.string(from: date)
        }
        return grouped.map { (month, entries) in
            MonthlyFuel(month: month, total: entries.reduce(0) { $0 + ( $1.amount ) })
        }
        .sorted { $0.month < $1.month }
    }
    
    // Wykresy - dane przebiegu
    var mileageData: [MileagePoint] {
        let sorted = fuelEntries.sorted { ($0.date ?? Date()) < ($1.date ?? Date()) }
        var cumulative: Double = 0
        return sorted.compactMap { entry in
            guard let date = entry.date else { return nil }
            cumulative += entry.mileage
            return MileagePoint(date: date, cumulativeMileage: cumulative)
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Spacer().frame(height: 16)
                Text("Statystyki")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 8)
                
                // WYKRESY NAD STATYSTYKAMI
                if #available(iOS 16.0, *) {
                    Chart {
                        ForEach(monthlyData) { item in
                            BarMark(
                                x: .value("Miesiąc", item.month),
                                y: .value("Zużycie (l)", item.total)
                            )
                        }
                    }
                    .frame(height: 200)
                    .padding(.horizontal)
                    
                    Chart {
                        ForEach(mileageData) { point in
                            LineMark(
                                x: .value("data", point.date),
                                y: .value("km", point.cumulativeMileage)
                            )
                            .foregroundStyle(.blue)
                            PointMark(
                                x: .value("data", point.date),
                                y: .value("km", point.cumulativeMileage)
                            )
                        }
                    }
                    .chartYAxisLabel("km")
                    .chartXAxisLabel("data")
                    .frame(height: 200)
                    .padding(.horizontal)
                } else {
                    Text("Wykresy dostępne tylko na iOS 16+")
                }
                
                Spacer().frame(height: 16)
                Text("Statystyki zużycia paliwa")
                    .font(.title)
                    .padding(.top)
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Liczba tankowań: \(totalEntries)")
                        .font(.headline)
                    Text("Łączna ilość paliwa: \(totalFuel, specifier: "%.2f") l")
                        .font(.headline)
                    Text("Średnia ilość paliwa na tankowanie: \(averageFuel, specifier: "%.2f") l")
                        .font(.headline)
                    
                    if let consumption = averageConsumption {
                        Text("Średnie zużycie: \(consumption, specifier: "%.2f") l/100km")
                            .font(.headline)
                    } else {
                        Text("Za mało danych do obliczenia zużycia.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 4)
                )
                .padding(.horizontal)
                
                Spacer()

            }
            .background(
                LinearGradient(gradient: Gradient(colors: [Color("AccentColor").opacity(0.3), Color.white]),
                               startPoint: .topLeading,
                               endPoint: .bottomTrailing)
                    .ignoresSafeArea()
            )
        }
    }
}

