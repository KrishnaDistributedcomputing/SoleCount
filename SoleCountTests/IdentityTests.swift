import Testing
@testable import SoleCount

/// Public identity of the free app. The Linux check in scripts/check_repo.sh
/// looks for these same strings. `make test` is what actually runs this file.
struct IdentityTests {
    @Test func privacySupportAndTermsStayOnThePublicPages() {
        #expect(AppLinks.privacyPolicy.absoluteString == "https://github.com/KrishnaDistributedcomputing/SoleCount/blob/main/docs/PRIVACY.md")
        #expect(AppLinks.support.absoluteString == "https://github.com/KrishnaDistributedcomputing/SoleCount/blob/main/docs/SUPPORT.md")
        #expect(AppLinks.termsOfUse.absoluteString == "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")
    }

    @Test func theAppStaysFreeAndKeepsItsProductId() {
        #expect(FeatureFlags.monetizationEnabled == false)
        #expect(StoreManager.proProductID == "com.krishnav.SoleCount.pro")
    }
}
