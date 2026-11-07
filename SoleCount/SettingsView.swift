import SwiftUI
import SwiftData

// Links you can change in one place.
// The privacy policy page must be public for App Review.
enum AppLinks {
    static let privacyPolicy = URL(string: "https://github.com/KrishnaDistributedcomputing/SoleCount/blob/main/docs/PRIVACY.md")!
    static let termsOfUse = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    static let support = URL(string: "https://github.com/KrishnaDistributedcomputing/SoleCount/blob/main/docs/SUPPORT.md")!
}

// Goals, reminders, export, and the privacy links.
struct SettingsView: View {
    @Environment(StoreManager.self) private var store
    @Environment(HealthSync.self) private var health
    @Environment(MotivationStore.self) private var motivation
    @Environment(\.dismiss) private var dismiss
    @Query private var sneakers: [Sneaker]
    @State private var showingPaywall = false
    @State private var reminderNote = ""

    var body: some View {
        @Bindable var store = store

        NavigationStack {
            List {
                if FeatureFlags.monetizationEnabled {
                    Section("SoleCount Pro") {
                        if store.isPro {
                            Label("Pro unlocked", systemImage: "checkmark.seal.fill")
                                .foregroundStyle(.green)
                        } else {
                            Button {
                                showingPaywall = true
                            } label: {
                                Label("Unlock Pro", systemImage: "star.fill")
                            }
                        }
                        Button("Restore Purchases") {
                            Task { await store.restore() }
                        }
                        .disabled(store.isLoading)
                    }
                } else {
                    Section {
                        Text("SoleCount is free. Every feature is included, and your shoes stay on this iPhone.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Apple Health") {
                    HealthConnectCard(
                        onConnect: { Task { await HealthCoordinator.connect(health: health, motivation: motivation, sneakers: sneakers) } },
                        onRefresh: { Task { await HealthCoordinator.refresh(health: health, motivation: motivation, sneakers: sneakers) } }
                    )
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }

                Section("Goals") {
                    Stepper("Daily steps: \(motivation.stepGoal)", value: Binding(
                        get: { motivation.stepGoal },
                        set: { motivation.setStepGoal($0) }
                    ), in: 2_000...30_000, step: 500)
                    Stepper("Weekly \(DistanceFormat.unitWord()): \(Int(DistanceFormat.displayValue(kilometers: motivation.weeklyKilometers)))", value: Binding(
                        get: { DistanceFormat.displayValue(kilometers: motivation.weeklyKilometers) },
                        set: { motivation.setWeeklyKilometers(DistanceFormat.kilometers(fromDisplay: $0)) }
                    ), in: 5.0...200.0, step: 1.0)
                }

                Section("Reminders") {
                    Toggle("Morning: what are you wearing?", isOn: Binding(
                        get: { motivation.morningReminder },
                        set: { newValue in Task { await setMorning(newValue) } }
                    ))
                    Toggle("Evening nudge if you're under the step goal", isOn: Binding(
                        get: { motivation.eveningNudge },
                        set: { newValue in Task { await setEvening(newValue) } }
                    ))
                    Toggle("Celebrate a new badge", isOn: Binding(
                        get: { motivation.milestoneAlerts },
                        set: { newValue in Task { await setMilestones(newValue) } }
                    ))
                    Toggle("Distance target at 80% and 100%", isOn: Binding(
                        get: { motivation.retirementAlerts },
                        set: { newValue in Task { await setRetirement(newValue) } }
                    ))
                    if !reminderNote.isEmpty {
                        Text(reminderNote)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Your data") {
                    ShareLink(
                        item: CSVShare(text: CollectionExport.csv(rows: sneakers.map { $0.asExportRow() })),
                        preview: SharePreview("SoleCount shoes")
                    ) {
                        Label("Export CSV", systemImage: "square.and.arrow.up")
                    }
                }

                Section {
                    NavigationLink {
                        AboutView()
                    } label: {
                        Label("About", systemImage: "info.circle")
                    }
                    .accessibilityIdentifier("aboutButton")
                }

                Section {
                    Text("Steps and distance are read from Apple Health and stay on this iPhone. They are not used for ads and they are not stored in iCloud. SoleCount is not a medical app.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showingPaywall) { PaywallView() }
            .alert("Store", isPresented: $store.showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(store.errorMessage)
            }
        }
    }

    private func setMorning(_ enabled: Bool) async {
        if enabled {
            let allowed = await WearReminder.requestAccess()
            motivation.setMorning(enabled: allowed, hour: motivation.morningHour, minute: motivation.morningMinute)
            reminderNote = allowed ? "" : "Notifications are off. You can allow them in the iPhone Settings app."
        } else {
            motivation.setMorning(enabled: false, hour: motivation.morningHour, minute: motivation.morningMinute)
        }
        await reschedule()
    }

    private func setEvening(_ enabled: Bool) async {
        if enabled {
            let allowed = await WearReminder.requestAccess()
            motivation.setEvening(enabled: allowed, hour: motivation.eveningHour, minute: motivation.eveningMinute)
            reminderNote = allowed ? "" : "Notifications are off. You can allow them in the iPhone Settings app."
        } else {
            motivation.setEvening(enabled: false, hour: motivation.eveningHour, minute: motivation.eveningMinute)
        }
        await reschedule()
    }

    private func setRetirement(_ enabled: Bool) async {
        if enabled {
            let allowed = await WearReminder.requestAccess()
            motivation.setRetirementAlerts(allowed)
            reminderNote = allowed ? "" : "Notifications are off. You can allow them in the iPhone Settings app."
        } else {
            motivation.setRetirementAlerts(false)
        }
    }

    private func setMilestones(_ enabled: Bool) async {
        if enabled {
            let allowed = await WearReminder.requestAccess()
            motivation.setMilestoneAlerts(allowed)
            reminderNote = allowed ? "" : "Notifications are off. You can allow them in the iPhone Settings app."
        } else {
            motivation.setMilestoneAlerts(false)
        }
    }

    private func reschedule() async {
        let steps = Int(motivation.todaySteps().rounded())
        let body = motivation.eveningNudge ? WearReminder.eveningCopy(stepsToday: steps, goal: motivation.stepGoal) : nil
        await WearReminder.reschedule(
            morning: motivation.morningReminder,
            morningHour: motivation.morningHour,
            morningMinute: motivation.morningMinute,
            evening: motivation.eveningNudge && body != nil,
            eveningHour: motivation.eveningHour,
            eveningMinute: motivation.eveningMinute,
            eveningBody: body
        )
    }
}
