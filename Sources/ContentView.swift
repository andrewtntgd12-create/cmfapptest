import SwiftUI

struct ContentView: View {
    @StateObject private var reader = BatteryReader()
    private let labels = ["Case", "L", "R"]

    var body: some View {
        VStack(spacing: 20) {
            Text("🎧 Buds Battery").font(.title2.bold())
            HStack(spacing: 12) {
                ForEach(0..<3, id: \.self) { i in
                    VStack(spacing: 6) {
                        Text(labels[i]).font(.caption).foregroundStyle(.secondary)
                        Text(reader.levels[i].map { "\($0)%" } ?? "--")
                            .font(.system(size: 30, weight: .bold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
                }
            }
            Button(action: { reader.start() }) {
                Text("Cerca").font(.headline).frame(maxWidth: .infinity).padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            Text(reader.status).font(.footnote).foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Text("Ordine dei valori: dipende da come il dispositivo espone i servizi.")
                .font(.caption2).foregroundStyle(.tertiary).multilineTextAlignment(.center)
        }
        .padding()
    }
}
