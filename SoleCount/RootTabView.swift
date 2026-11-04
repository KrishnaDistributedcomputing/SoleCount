import SwiftUI
import SwiftData

/// Today, the collection, stats, and the calendar.
struct RootTabView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(HealthSync.self) private var health
    @Environment(MotivationStore.self) private var motivation
    @Query private var sneakers: [Sneaker]

    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("Today", systemImage: "sun.max.fill") }
            SneakerListView()
                .tabItem { Label("Collection", systemImage: "shoe.2.fill") }
            StatsDashboardView()
                .tabItem { Label("Stats", systemImage: "chart.bar.fill") }
            WearCalendarView()
                .tabItem { Label("Calendar", systemImage: "calendar") }
        }
        .task {
            motivation.publishWidget()
            HealthCoordinator.rememberCurrentBadges(motivation: motivation, sneakers: sneakers)
            await HealthCoordinator.refresh(health: health, motivation: motivation, sneakers: sneakers)
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            Task {
                await HealthCoordinator.refresh(health: health, motivation: motivation, sneakers: sneakers)
            }
        }
    }
}
