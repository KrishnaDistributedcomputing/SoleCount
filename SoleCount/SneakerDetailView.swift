import SwiftUI
import SwiftData

// The screen for one pair: big "Wore today" button, stats, chart, retire.
struct SneakerDetailView: View {
    @Environment(StoreManager.self) private var store
    @Bindable var sneaker: Sneaker

    @State private var showingPaywall = false
    @State private var showingLimitAlert = false
    @State private var buttonScale: CGFloat = 1.0
    @State private var celebrationScale: CGFloat = 0.5

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Hero photo
                SneakerPhoto(data: sneaker.photoData, size: 240)
                    .shadow(color: Color.accentColor.opacity(0.3), radius: 20, y: 10)

                // Title and brand
                VStack(spacing: 8) {
                    Text(sneaker.name)
                        .font(.largeTitle.bold())
                        .multilineTextAlignment(.center)

                    if !sneaker.brand.isEmpty {
                        Text(sneaker.brand)
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }

                    if sneaker.isRetired {
                        Label("Retired", systemImage: "archivebox.fill")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(.orange.gradient)
                            )
                            .padding(.top, 8)
                    }
                }

                // Stats cards
                HStack(spacing: 12) {
                    ModernStatCard(
                        icon: "figure.walk",
                        value: "\(sneaker.wearCount)",
                        label: "Wears",
                        color: .blue
                    )
                    ModernStatCard(
                        icon: "dollarsign.circle",
                        value: sneaker.costPerWear?.asCurrency ?? "–",
                        label: "Per Wear",
                        color: .green
                    )
                    ModernStatCard(
                        icon: "tag",
                        value: sneaker.price.asCurrency,
                        label: "Price",
                        color: .purple
                    )
                }

                // Wear limit progress
                if let limit = sneaker.wearLimit, limit > 0 {
                    VStack(spacing: 8) {
                        HStack {
                            Text("Wear Goal")
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                            Text("\(sneaker.wearCount) / \(limit)")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.secondary)
                        }
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.secondary.opacity(0.2))
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.accentColor, Color.accentColor.opacity(0.7)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: geo.size.width * min(1.0, Double(sneaker.wearCount) / Double(limit)))
                            }
                        }
                        .frame(height: 12)
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                }

                // Wore today button with animation
                if !sneaker.isRetired {
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            buttonScale = 0.95
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                                buttonScale = 1.0
                            }
                        }
                        logWear()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: sneaker.woreToday ? "checkmark.circle.fill" : "plus.circle.fill")
                                .font(.title2)
                                .symbolEffect(.bounce, value: sneaker.wearCount)

                            Text(sneaker.woreToday ? "Wore Them Again" : "Wore Today")
                                .font(.title3.bold())
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: Color.accentColor.opacity(0.5), radius: 12, y: 6)
                        )
                    }
                    .scaleEffect(buttonScale)
                    .sensoryFeedback(.success, trigger: sneaker.wearCount)

                    if sneaker.woreToday {
                        Button {
                            withAnimation {
                                sneaker.undoTodayWear()
                            }
                        } label: {
                            Label("Undo Today's Wear", systemImage: "arrow.uturn.backward")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.red)
                        }
                    }
                }

                // Chart section
                chartSection
                    .padding(.top, 8)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(sneaker.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        withAnimation {
                            sneaker.isRetired.toggle()
                        }
                    } label: {
                        Label(
                            sneaker.isRetired ? "Unretire" : "Retire",
                            systemImage: sneaker.isRetired ? "arrow.uturn.backward" : "archivebox"
                        )
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.headline)
                }
            }
        }
        .alert("Time to Retire This Pair?", isPresented: $showingLimitAlert) {
            Button("Retire Now") {
                withAnimation {
                    sneaker.isRetired = true
                }
            }
            Button("Keep Wearing", role: .cancel) { }
        } message: {
            Text("You've reached the wear limit you set for this pair. Congratulations!")
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
    }

    @ViewBuilder
    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundStyle(Color.accentColor)
                Text("Wear History")
                    .font(.title3.bold())
                Spacer()
                Text("Last 6 Months")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if store.isPro {
                WearChartView(wearDates: sneaker.wearDates)
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            } else {
                Button {
                    showingPaywall = true
                } label: {
                    VStack(spacing: 12) {
                        Image(systemName: "lock.fill")
                            .font(.title2)
                            .foregroundStyle(Color.accentColor)
                        Text("Unlock Wear History Charts")
                            .font(.headline)
                        Text("Available with SoleCount Pro")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .strokeBorder(Color.accentColor.opacity(0.3), lineWidth: 2, antialiased: true)
                            )
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func logWear() {
        sneaker.logWear()
        if let limit = sneaker.wearLimit, limit > 0, sneaker.wearCount == limit {
            showingLimitAlert = true
        }
    }
}

/// Modern stat card with icon and color
struct ModernStatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color.gradient)

            Text(value)
                .font(.title2.bold())
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
        )
        .accessibilityElement(children: .combine)
    }
}
