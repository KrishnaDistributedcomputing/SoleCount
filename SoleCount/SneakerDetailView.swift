import SwiftUI
import SwiftData

// The screen for one pair: big "Wore today" button, stats, chart, retire.
struct SneakerDetailView: View {
    @Environment(StoreManager.self) private var store
    @Bindable var sneaker: Sneaker

    @State private var showingPaywall = false
    @State private var showingLimitAlert = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                SneakerPhoto(data: sneaker.photoData, size: 200)

                VStack(spacing: 4) {
                    Text(sneaker.name)
                        .font(.title.bold())
                        .multilineTextAlignment(.center)
                    if !sneaker.brand.isEmpty {
                        Text(sneaker.brand)
                            .foregroundStyle(.secondary)
                    }
                    if sneaker.isRetired {
                        Label("Retired", systemImage: "archivebox.fill")
                            .font(.subheadline.bold())
                            .foregroundStyle(.orange)
                            .padding(.top, 4)
                    }
                }

                HStack(spacing: 12) {
                    StatCard(title: "Wears", value: "\(sneaker.wearCount)")
                    StatCard(title: "Cost per wear", value: sneaker.costPerWear?.asCurrency ?? "–")
                    StatCard(title: "Price", value: sneaker.price.asCurrency)
                }

                if let limit = sneaker.wearLimit, limit > 0 {
                    ProgressView(value: Double(min(sneaker.wearCount, limit)), total: Double(limit)) {
                        Text("\(sneaker.wearCount) of \(limit) wears")
                            .font(.subheadline)
                    }
                }

                if !sneaker.isRetired {
                    Button {
                        logWear()
                    } label: {
                        Label(sneaker.woreToday ? "Wore them again" : "Wore today",
                              systemImage: "checkmark.circle.fill")
                            .font(.title2.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .sensoryFeedback(.success, trigger: sneaker.wearCount)

                    if sneaker.woreToday {
                        Button("Undo today's wear", role: .destructive) {
                            sneaker.undoTodayWear()
                        }
                        .font(.footnote)
                    }
                }

                chartSection
            }
            .padding()
        }
        .navigationTitle(sneaker.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(sneaker.isRetired ? "Unretire" : "Retire") {
                    sneaker.isRetired.toggle()
                }
            }
        }
        .alert("Time to retire this pair?", isPresented: $showingLimitAlert) {
            Button("Retire now") { sneaker.isRetired = true }
            Button("Keep wearing", role: .cancel) { }
        } message: {
            Text("You've reached the wear limit you set for this pair.")
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
    }

    @ViewBuilder
    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Wear history (last 6 months)")
                .font(.headline)

            if store.isPro {
                WearChartView(wearDates: sneaker.wearDates)
            } else {
                Button {
                    showingPaywall = true
                } label: {
                    HStack {
                        Image(systemName: "lock.fill")
                        Text("Unlock the wear history chart with Pro")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func logWear() {
        sneaker.logWear()
        if let limit = sneaker.wearLimit, limit > 0, sneaker.wearCount == limit {
            showingLimitAlert = true
        }
    }
}
