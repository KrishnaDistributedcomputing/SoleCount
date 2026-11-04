import SwiftData
import SwiftUI

// One pair: wear button, distance, photos, and the charts.
struct SneakerDetailView: View {
    @Environment(StoreManager.self) private var store
    @Environment(HealthSync.self) private var health
    @Environment(MotivationStore.self) private var motivation
    @Environment(\.modelContext) private var modelContext
    @Environment(\.shoeNamespace) private var shoeNamespace
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query private var allSneakers: [Sneaker]
    @Bindable var sneaker: Sneaker

    @State private var showingPaywall = false
    @State private var showingLimitAlert = false
    @State private var showingEdit = false
    @State private var buttonScale: CGFloat = 1

    private var tint: Color { ShoeTheme.accent(for: sneaker.shoeType) }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                hero
                titleBlock
                stats
                if let note = sneaker.shareNote {
                    Text(note)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                if let limit = sneaker.wearLimit, limit > 0 {
                    wearGoal(limit)
                }
                if !sneaker.isRetired {
                    wearButton
                }
                if store.hasFullAccess, sneaker.replaceAtKilometers > 0 {
                    MileageGoalCard(
                        meters: sneaker.cachedDistanceMeters,
                        goalKilometers: sneaker.replaceAtKilometers,
                        tint: tint
                    )
                }
                HealthConnectCard(onConnect: connect, onRefresh: refresh)
                details
                charts
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(sneaker.name)
        .navigationBarTitleDisplayMode(.inline)
        .modifier(ShoeZoomTransition(id: sneaker.persistentModelID, space: shoeNamespace))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Edit", systemImage: "pencil") { showingEdit = true }
                    Button(sneaker.isRetired ? "Bring back" : "Move to Hall of Fame", systemImage: "archivebox") {
                        withAnimation(reduceMotion ? nil : .spring) {
                            sneaker.isRetired.toggle()
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel("More")
            }
        }
        .alert("Time to Retire This Pair?", isPresented: $showingLimitAlert) {
            Button("Retire Now") { sneaker.isRetired = true }
            Button("Keep Wearing", role: .cancel) { }
        } message: {
            Text("You've reached the wear limit you set for this pair. Congratulations!")
        }
        .sheet(isPresented: $showingPaywall) { PaywallView() }
        .sheet(isPresented: $showingEdit) { AddSneakerView(existing: sneaker) }
        .sensoryFeedback(.success, trigger: sneaker.wearCount)
    }

    private var hero: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(LinearGradient(colors: ShoeTheme.colors(for: sneaker.shoeType), startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(height: 280)
            if sneaker.gallery.count > 1 {
                TabView {
                    ForEach(Array(sneaker.gallery.enumerated()), id: \.offset) { _, data in
                        SneakerPhoto(data: data, size: 220)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .automatic))
                .frame(height: 260)
            } else {
                SneakerPhoto(data: sneaker.gallery.first, size: 220)
                    .shadow(color: .black.opacity(0.25), radius: 16, y: 8)
            }
        }
    }

    private var titleBlock: some View {
        VStack(spacing: 8) {
            Text(sneaker.name)
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
            HStack(spacing: 6) {
                Image(systemName: sneaker.shoeType.symbolName)
                    .foregroundStyle(tint)
                    .accessibilityHidden(true)
                Text(subtitle)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            if sneaker.isRetired {
                Label("Hall of Fame", systemImage: "archivebox.fill")
                    .font(.headline)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(.orange.gradient))
            }
        }
    }

    private var subtitle: String {
        var parts: [String] = []
        if !sneaker.brand.isEmpty { parts.append(sneaker.brand) }
        parts.append(sneaker.shoeType.rawValue)
        if !sneaker.colorway.isEmpty { parts.append(sneaker.colorway) }
        if !sneaker.size.isEmpty { parts.append("Size \(sneaker.size)") }
        return parts.joined(separator: " · ")
    }

    private var stats: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                ModernStatCard(icon: "figure.walk", value: "\(sneaker.wearCount)", label: "Wears", color: .blue)
                ModernStatCard(icon: "dollarsign.circle", value: sneaker.costPerWear?.asCurrency ?? "–", label: "Per Wear", color: .green)
                ModernStatCard(icon: "tag", value: sneaker.price.asCurrency, label: "Price", color: .purple)
            }
            HStack(spacing: 12) {
                ModernStatCard(
                    icon: "point.topleft.down.to.point.bottomright.curvepath",
                    value: sneaker.healthUpdatedAt == nil && sneaker.cachedDistanceMeters == 0 ? "–" : DistanceFormat.string(meters: sneaker.cachedDistanceMeters),
                    label: "Distance",
                    color: tint
                )
                ModernStatCard(
                    icon: "shoeprints.fill",
                    value: sneaker.healthUpdatedAt == nil && sneaker.cachedSteps == 0 ? "–" : DistanceFormat.steps(sneaker.cachedSteps),
                    label: "Steps",
                    color: .orange
                )
                ModernStatCard(
                    icon: "divide",
                    value: sneaker.averageMetersPerWear.map { DistanceFormat.string(meters: $0) } ?? "–",
                    label: "Avg / wear",
                    color: .teal
                )
            }
        }
    }

    private func wearGoal(_ limit: Int) -> some View {
        VStack(spacing: 8) {
            HStack {
                Text("Wear Goal")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text("\(sneaker.wearCount) / \(limit)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText())
            }
            ProgressView(value: min(1, Double(sneaker.wearCount) / Double(limit)))
                .tint(tint)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private var wearButton: some View {
        VStack(spacing: 8) {
            Button {
                withAnimation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.6)) {
                    buttonScale = 0.95
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(reduceMotion ? nil : .spring) { buttonScale = 1 }
                }
                logWear()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: sneaker.woreToday ? "checkmark.circle.fill" : "plus.circle.fill")
                        .font(.title2)
                        .symbolEffect(.bounce, value: reduceMotion ? 0 : sneaker.wearCount)
                    Text(sneaker.woreToday ? "Wore Them Again" : "Wore Today")
                        .font(.title3.bold())
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(LinearGradient(colors: ShoeTheme.colors(for: sneaker.shoeType), startPoint: .topLeading, endPoint: .bottomTrailing))
                        .shadow(color: tint.opacity(0.4), radius: 12, y: 6)
                )
                .foregroundStyle(.white)
            }
            .scaleEffect(buttonScale)
            .accessibilityHint("Logs that you wore this pair")

            if sneaker.woreToday {
                Button {
                    withAnimation(reduceMotion ? nil : .spring) { sneaker.undoTodayWear() }
                    Task { await HealthCoordinator.refresh(health: health, motivation: motivation, sneakers: allSneakers) }
                } label: {
                    Label("Undo Today's Wear", systemImage: "arrow.uturn.backward")
                        .font(.subheadline.weight(.medium))
                }
                .foregroundStyle(.red)
            }
        }
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 8) {
            LabeledContent("Condition", value: sneaker.condition.rawValue)
            LabeledContent("Purchased", value: sneaker.purchaseDate.formatted(date: .abbreviated, time: .omitted))
            if !sneaker.notes.isEmpty {
                Text(sneaker.notes)
                    .font(.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    @ViewBuilder
    private var charts: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Last 6 months")
                .font(.title3.bold())
            if store.hasFullAccess {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Distance")
                        .font(.headline)
                    DistanceChartView(monthlyMeters: sneaker.monthlyMeters, tint: tint)
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                VStack(alignment: .leading, spacing: 8) {
                    Text("Wears")
                        .font(.headline)
                    WearChartView(wearDates: sneaker.wearDates)
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            } else {
                Button { showingPaywall = true } label: {
                    VStack(spacing: 8) {
                        Image(systemName: "lock.fill")
                        Text("Unlock the distance and wear charts")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
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
        Task { await HealthCoordinator.refresh(health: health, motivation: motivation, sneakers: allSneakers) }
    }

    private func connect() {
        Task { await HealthCoordinator.connect(health: health, motivation: motivation, sneakers: allSneakers) }
    }

    private func refresh() {
        Task { await HealthCoordinator.refresh(health: health, motivation: motivation, sneakers: allSneakers) }
    }
}
