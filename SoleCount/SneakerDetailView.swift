import SwiftData
import SwiftUI
import UIKit

// One pair. The photo is the hero. The name, brand, and fit sit under it.
// Size, wears, activities, and the other facts follow.
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
    @State private var showingSendOff = false
    @State private var buttonScale: CGFloat = 1
    @State private var cheer = 0
    @State private var nextActivity: WearActivity = .casual

    private var tint: Color { ShoeTheme.accent(for: sneaker.shoeType) }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                hero
                titleBlock
                if !sneaker.sizeLabel.isEmpty {
                    sizeBlock
                }
                stats
                if let note = sneaker.shareNote {
                    Text(note)
                        .font(.subheadline)
                        .foregroundStyle(ShoeTheme.softText)
                }
                if let limit = sneaker.wearLimit, limit > 0 {
                    wearGoal(limit)
                }
                if !sneaker.isRetired {
                    wearButton
                }
                wearHistory
                if let fraction = sneaker.lifeFraction {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Distance target")
                            .font(.headline)
                        LifeBar(fraction: fraction)
                        Text(DistanceFormat.string(meters: sneaker.totalMeters))
                            .font(.caption)
                            .foregroundStyle(ShoeTheme.softText)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .warmCard()
                }
                SoleCheckSection(sneaker: sneaker)
                if store.hasFullAccess, sneaker.replaceAtKilometers > 0 {
                    MileageGoalCard(
                        meters: sneaker.totalMeters,
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
        .background(ShoeTheme.canvas)
        .navigationTitle(sneaker.name)
        .navigationBarTitleDisplayMode(.inline)
        .modifier(ShoeZoomTransition(id: sneaker.persistentModelID, space: shoeNamespace))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Edit", systemImage: "pencil") { showingEdit = true }
                    Button(sneaker.isRetired ? "Bring back" : "Retire this pair", systemImage: "archivebox") {
                        if sneaker.isRetired {
                            sneaker.isRetired = false
                        } else {
                            sneaker.isRetired = true
                            showingSendOff = true
                        }
                    }
                    .accessibilityIdentifier("retirePairButton")
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel("More")
            }
        }
        .alert("This pair reached the wear goal you set", isPresented: $showingLimitAlert) {
            Button("Retire Now") {
                sneaker.isRetired = true
                showingSendOff = true
            }
            Button("Keep Wearing", role: .cancel) { }
        } message: {
            Text("You can retire it now, or keep wearing it. Both are good.")
        }
        .sheet(isPresented: $showingPaywall) { PaywallView() }
        .sheet(isPresented: $showingEdit) { AddSneakerView(existing: sneaker) }
        .sheet(isPresented: $showingSendOff) {
            SendOffView(
                name: sneaker.name,
                meters: sneaker.totalMeters,
                wears: sneaker.wearCount,
                cost: sneaker.costPerWear,
                daysOwned: PairTotals.daysOwned(from: sneaker.purchaseDate, to: .now, calendar: .current)
            )
        }
        .sensoryFeedback(.success, trigger: sneaker.wearCount)
    }

    private var hero: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(LinearGradient(colors: ShoeTheme.colors(for: sneaker.shoeType), startPoint: .topLeading, endPoint: .bottomTrailing))
            if sneaker.gallery.count > 1 {
                TabView {
                    ForEach(Array(sneaker.gallery.enumerated()), id: \.offset) { _, data in
                        heroPicture(data)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .automatic))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                heroPicture(sneaker.gallery.first)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 340)
        .accessibilityElement(children: .ignore)
        .accessibilityIdentifier("detailPhoto")
        .accessibilityLabel(sneaker.gallery.isEmpty ? "No photo yet" : "Photo saved")
    }

    /// A large photo of the shoe, or the same placeholder the rest of the app uses.
    @ViewBuilder
    private func heroPicture(_ data: Data?) -> some View {
        if let data, let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .frame(maxHeight: 300)
                .shadow(color: .black.opacity(0.25), radius: 16, y: 8)
                .accessibilityHidden(true)
        } else {
            SneakerPhoto(data: nil, size: 240)
        }
    }

    private var titleBlock: some View {
        VStack(spacing: 8) {
            Text(sneaker.name)
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity)
                .accessibilityIdentifier("detailName")
                .accessibilityAddTraits(.isHeader)
            if !sneaker.brand.isEmpty {
                Text(sneaker.brand)
                    .font(.title2)
                    .foregroundStyle(ShoeTheme.softText)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity)
                    .accessibilityIdentifier("detailBrand")
            }
            VStack(spacing: 2) {
                Text("Fit")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(ShoeTheme.softText)
                Text(sneaker.fit.label)
                    .font(.title3.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("detailFit")
            .accessibilityLabel("Fit, \(sneaker.fit.label)")
            if sneaker.isRetired {
                Label("Hall of Fame", systemImage: "archivebox.fill")
                    .font(.headline)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .foregroundStyle(ShoeTheme.onCoral)
                    .background(Capsule().fill(ShoeTheme.coral))
            }
        }
    }

    private var sizeBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Size")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(ShoeTheme.softText)
            Text(sneaker.sizeLabel)
                .font(.title2.bold())
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("shoeSizeValue")
            if let line = sneaker.sizeEquivalentLine {
                Text(line)
                    .font(.body)
                    .foregroundStyle(ShoeTheme.softText)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("shoeSizeEquivalents")
            } else {
                Text("Saved as typed. This size is not on the conversion chart.")
                    .font(.body)
                    .foregroundStyle(ShoeTheme.softText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .warmCard()
    }

    private var stats: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                ModernStatCard(icon: "figure.walk", value: sneaker.wearCount.formatted(), label: "Wears", color: .blue)
                ModernStatCard(icon: "dollarsign.circle", value: sneaker.costPerWear?.asCurrency ?? "–", label: "Per Wear", color: ShoeTheme.mintTint)
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
                    color: ShoeTheme.flame
                )
                ModernStatCard(
                    icon: "divide",
                    value: sneaker.averageMetersPerWear.map { DistanceFormat.string(meters: $0) } ?? "–",
                    label: "Avg / wear",
                    color: ShoeTheme.goldTint
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
                Text("\(sneaker.wearCount.formatted()) / \(limit.formatted())")
                    .font(.subheadline)
                    .foregroundStyle(ShoeTheme.softText)
                    .contentTransition(.numericText())
            }
            ProgressView(value: min(1, Double(sneaker.wearCount) / Double(limit)))
                .tint(tint)
        }
        .padding()
        .warmCard()
    }

    private var wearButton: some View {
        VStack(spacing: 8) {
            Picker("Activity", selection: $nextActivity) {
                ForEach(WearActivity.allCases) { activity in
                    Label(activity.rawValue, systemImage: activity.symbolName).tag(activity)
                }
            }
            .pickerStyle(.menu)
            .accessibilityIdentifier("wearActivityPicker")
            .accessibilityValue(nextActivity.rawValue)
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
                        .symbolEffect(.bounce, value: reduceMotion || LaunchFlags.screenshots ? 0 : sneaker.wearCount)
                    Text(sneaker.woreToday ? "Wore Them Again" : "Wore Today")
                        .font(.title3.bold())
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(LinearGradient(colors: ShoeTheme.colors(for: sneaker.shoeType), startPoint: .topLeading, endPoint: .bottomTrailing))
                        .shadow(color: ShoeTheme.glow.opacity(0.45), radius: cheer > 0 ? 18 : 10, y: 6)
                )
                .foregroundStyle(ShoeTheme.ink)
            }
            .scaleEffect(buttonScale)
            .accessibilityIdentifier("woreTodayButton")
            .accessibilityHint("Logs that you wore this pair for the activity you picked")
            .overlay { ConfettiBurst(trigger: cheer) }

            if sneaker.woreToday {
                Button {
                    withAnimation(reduceMotion ? nil : .spring) { sneaker.undoTodayWear() }
                    Task { await HealthCoordinator.refresh(health: health, motivation: motivation, sneakers: allSneakers) }
                } label: {
                    Label("Undo Today's Wear", systemImage: "arrow.uturn.backward")
                        .font(.subheadline.weight(.medium))
                }
                .foregroundStyle(ShoeTheme.ink)
            }
        }
    }

    private var wearHistory: some View {
        let records = sneaker.wearRecords
        let latest = Array(records.reversed().prefix(12))
        return Group {
            if !latest.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Wear history")
                        .font(.headline)
                        .accessibilityIdentifier("wearHistoryTitle")
                    ForEach(Array(latest.enumerated()), id: \.offset) { _, record in
                        HStack {
                            Label(record.activity.rawValue, systemImage: record.activity.symbolName)
                            Spacer()
                            Text(record.date.formatted(date: .abbreviated, time: .omitted))
                                .foregroundStyle(.secondary)
                        }
                        .font(.subheadline)
                        .accessibilityElement(children: .combine)
                        .accessibilityIdentifier("wearHistoryRow")
                        .accessibilityLabel("\(record.activity.rawValue), \(record.date.formatted(date: .abbreviated, time: .omitted))")
                    }
                    if records.count > latest.count {
                        Text("Showing the latest \(latest.count).")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .warmCard()
                .accessibilityIdentifier("wearHistory")
            }
        }
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 8) {
            LabeledContent("Type", value: sneaker.shoeType.rawValue)
                .accessibilityIdentifier("shoeTypeValue")
            if !sneaker.colorway.isEmpty {
                LabeledContent("Colorway", value: sneaker.colorway)
                    .fixedSize(horizontal: false, vertical: true)
            }
            LabeledContent("Condition", value: sneaker.condition.rawValue)
            LabeledContent("Purchased", value: sneaker.purchaseDate.formatted(date: .abbreviated, time: .omitted))
            if !sneaker.notes.isEmpty {
                Text(sneaker.notes)
                    .font(.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .warmCard()
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
                .warmCard()
                VStack(alignment: .leading, spacing: 8) {
                    Text("Wears")
                        .font(.headline)
                    WearChartView(wearDates: sneaker.wearDates)
                }
                .padding()
                .warmCard()
            } else {
                Button { showingPaywall = true } label: {
                    VStack(spacing: 8) {
                        Image(systemName: "lock.fill")
                        Text("Unlock the distance and wear charts")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .warmCard()
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func logWear() {
        cheer += 1
        sneaker.logWear(activity: nextActivity)
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
