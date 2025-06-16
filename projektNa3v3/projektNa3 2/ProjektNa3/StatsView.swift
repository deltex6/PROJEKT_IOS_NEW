import SwiftUI

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
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
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

                // Ikona – może być dodatkowym elementem wizualnym (tutaj pozostawiamy ją jako ozdobnik)
                Image(systemName: "chart.bar.fill")
                    .resizable()
                    .frame(width: 150, height: 150)
                    .foregroundColor(.green)
                    .padding(.bottom)
                    .onTapGesture {
                        // Można rozszerzyć akcję na przykład o pokazywanie szczegółowego wykresu
                        print("Statystyki tapped")
                    }
            }
            .navigationTitle("Statystyki")
            .background(
                LinearGradient(gradient: Gradient(colors: [Color("AccentColor").opacity(0.3), Color.white]),
                               startPoint: .topLeading,
                               endPoint: .bottomTrailing)
                    .ignoresSafeArea()
            )
        }
    }
}

