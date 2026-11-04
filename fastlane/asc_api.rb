# frozen_string_literal: true
#
# Small App Store Connect API helper for SoleCount.
# Uses only Ruby's standard library (no extra gems), and the same .p8 API key as fastlane.
#
# It automates the App Store Connect steps that fastlane does not cover with an API key:
#   - register the bundle ID
#   - app price (Free) and countries
#   - age rating questionnaire (all "None" / "No")
#   - the "SoleCount Pro" In-App Purchase: create, name, $0.99 price, countries, review screenshot
#
# Every step is safe to run again: it checks first and skips work that is already done.
# Apple docs: https://developer.apple.com/documentation/appstoreconnectapi
#
# Run by fastlane (`fastlane setup` / `fastlane release`), or by hand:
#   ASC_KEY_ID=... ASC_ISSUER_ID=... ASC_KEY_PATH=~/.appstoreconnect/private_keys/AuthKey_XXXX.p8 \
#     ruby fastlane/asc_api.rb status

require "json"
require "net/http"
require "openssl"
require "base64"
require "digest"
require "uri"

module SoleCountASC
  class Error < StandardError
    attr_reader :status, :errors

    def initialize(message, status: nil, errors: [])
      super(message)
      @status = status
      @errors = errors
    end
  end

  # Answers for the age rating questionnaire. SoleCount has no objectionable content,
  # no ads, no chat, no web browser, no user-generated content -> rated 4+.
  AGE_RATING_NONE = {
    # "None / Infrequent / Frequent" questions
    "alcoholTobaccoOrDrugUseOrReferences" => "NONE",
    "contests" => "NONE",
    "gamblingSimulated" => "NONE",
    "gunsOrOtherWeapons" => "NONE",
    "horrorOrFearThemes" => "NONE",
    "matureOrSuggestiveThemes" => "NONE",
    "medicalOrTreatmentInformation" => "NONE",
    "profanityOrCrudeHumor" => "NONE",
    "sexualContentGraphicAndNudity" => "NONE",
    "sexualContentOrNudity" => "NONE",
    "violenceCartoonOrFantasy" => "NONE",
    "violenceRealistic" => "NONE",
    "violenceRealisticProlongedGraphicOrSadistic" => "NONE",
    # Yes / No questions
    "advertising" => false,
    "ageAssurance" => false,
    "gambling" => false,
    "healthOrWellnessTopics" => false,
    "lootBox" => false,
    "messagingAndChat" => false,
    "parentalControls" => false,
    "socialMedia" => false,
    "unrestrictedWebAccess" => false,
    "userGeneratedContent" => false,
  }.freeze

  # Keys we never answer automatically (overrides / optional info).
  AGE_RATING_SKIP = %w[kidsAgeBand ageRatingOverride ageRatingOverrideV2 koreaAgeRatingOverride
                       developerAgeRatingInfoUrl gamblingAndContests seventeenPlus socialMediaAgeRestricted].freeze

  class Client
    BASE = "https://api.appstoreconnect.apple.com"

    def initialize(key_id:, issuer_id:, key_pem:, log: method(:puts))
      raise Error, "ASC_KEY_ID is empty" if key_id.to_s.strip.empty?
      raise Error, "ASC_ISSUER_ID is empty" if issuer_id.to_s.strip.empty?

      @key_id = key_id.strip
      @issuer_id = issuer_id.strip
      @key = OpenSSL::PKey.read(key_pem)
      @log = log
      @token = nil
      @token_expires = 0
    end

    # Builds a client from environment variables:
    #   ASC_KEY_ID, ASC_ISSUER_ID and either ASC_KEY_PATH (file) or ASC_KEY_P8 (base64 or raw text).
    def self.from_env
      pem = if ENV["ASC_KEY_PATH"].to_s.strip != ""
              File.read(File.expand_path(ENV["ASC_KEY_PATH"].strip))
            elsif ENV["ASC_KEY_P8"].to_s.strip != ""
              raw = ENV["ASC_KEY_P8"].strip
              raw.include?("BEGIN PRIVATE KEY") ? raw : Base64.decode64(raw)
            else
              default = File.expand_path("~/.appstoreconnect/private_keys/AuthKey_#{ENV['ASC_KEY_ID']}.p8")
              raise Error, "No API key found. Set ASC_KEY_PATH (see AUTOMATION.md)." unless File.exist?(default)

              File.read(default)
            end
      new(key_id: ENV["ASC_KEY_ID"], issuer_id: ENV["ASC_ISSUER_ID"], key_pem: pem)
    end

    # ---------------------------------------------------------------- auth

    # JSON Web Token signed with ES256, as Apple requires (valid 20 minutes max).
    def token
      now = Time.now.to_i
      return @token if @token && now < @token_expires - 60

      header = { alg: "ES256", kid: @key_id, typ: "JWT" }
      payload = { iss: @issuer_id, iat: now, exp: now + 1200, aud: "appstoreconnect-v1" }
      signing_input = "#{b64url(header.to_json)}.#{b64url(payload.to_json)}"
      der = @key.sign(OpenSSL::Digest.new("SHA256"), signing_input)
      # OpenSSL returns a DER signature; JWT needs the raw 64-byte r||s form.
      r, s = OpenSSL::ASN1.decode(der).value.map { |int| int.value.to_s(2).rjust(32, "\x00".b) }
      @token = "#{signing_input}.#{b64url(r + s)}"
      @token_expires = now + 1200
      @token
    end

    # ---------------------------------------------------------------- HTTP

    def get(path, query = {})
      request(:get, path, nil, query)
    end

    def post(path, body)
      request(:post, path, body)
    end

    def patch(path, body)
      request(:patch, path, body)
    end

    # GET that returns nil instead of raising on 404 (resource not created yet).
    def get_or_nil(path, query = {})
      get(path, query)
    rescue Error => e
      raise unless e.status == 404

      nil
    end

    # Follows "links.next" pages and returns all "data" items.
    def get_all(path, query = {})
      items = []
      url = build_uri(path, query)
      loop do
        page = request_uri(:get, url)
        items.concat(Array(page["data"]))
        nxt = page.dig("links", "next")
        break if nxt.nil? || nxt.empty?

        url = URI(nxt)
      end
      items
    end

    def request(method, path, body = nil, query = {})
      request_uri(method, build_uri(path, query), body)
    end

    # ---------------------------------------------------------------- bundle ID

    def ensure_bundle_id(identifier, name)
      existing = get_all("/v1/bundleIds", "filter[identifier]" => identifier, "limit" => 200)
                 .find { |b| b.dig("attributes", "identifier") == identifier }
      record = if existing
                 say "Bundle ID #{identifier} already registered."
                 existing
               else
                 created = post("/v1/bundleIds", data: {
                   type: "bundleIds",
                   attributes: { identifier: identifier, name: name, platform: "IOS" }
                 })["data"]
                 say "Registered bundle ID #{identifier}."
                 created
               end
      ensure_iap_capability(record["id"])
      record
    end

    # New iOS App IDs include In-App Purchase by default. This turns it on if Apple left it off.
    def ensure_iap_capability(bundle_resource_id)
      caps = get_all("/v1/bundleIds/#{bundle_resource_id}/bundleIdCapabilities")
      if caps.any? { |c| c.dig("attributes", "capabilityType") == "IN_APP_PURCHASE" }
        say "In-App Purchase capability is already on for this bundle ID."
        return
      end

      post("/v1/bundleIdCapabilities", data: {
        type: "bundleIdCapabilities",
        attributes: { capabilityType: "IN_APP_PURCHASE" },
        relationships: { bundleId: { data: { type: "bundleIds", id: bundle_resource_id } } }
      })
      say "Turned on the In-App Purchase capability."
    rescue Error => e
      raise if [401, 403].include?(e.status)

      say "Could not change the In-App Purchase capability (#{e.message}). New iOS App IDs include it by default, so setup continues."
    end

    # ---------------------------------------------------------------- app

    def find_app(bundle_id)
      get_all("/v1/apps", "filter[bundleId]" => bundle_id, "limit" => 50)
        .find { |a| a.dig("attributes", "bundleId") == bundle_id }
    end

    # The version that is live in the App Store, or nil before the first release.
    def live_version(app_id)
      get("/v1/apps/#{app_id}/appStoreVersions",
          "filter[appStoreState]" => "READY_FOR_SALE", "filter[platform]" => "IOS", "limit" => 1)["data"].first
    end

    def set_app_price_free(app_id)
      if get_or_nil("/v1/apps/#{app_id}/appPriceSchedule").to_h["data"]
        say "App price already set."
        return
      end

      free = get_all("/v1/apps/#{app_id}/appPricePoints", "filter[territory]" => "USA", "limit" => 200)
             .find { |p| p.dig("attributes", "customerPrice").to_f.zero? }
      raise Error, "Could not find the Free price point." unless free

      post("/v1/appPriceSchedules", {
        data: {
          type: "appPriceSchedules",
          relationships: {
            app: { data: { type: "apps", id: app_id } },
            baseTerritory: { data: { type: "territories", id: "USA" } },
            manualPrices: { data: [{ type: "appPrices", id: "${price1}" }] }
          }
        },
        included: [{
          type: "appPrices", id: "${price1}",
          attributes: { startDate: nil },
          relationships: { appPricePoint: { data: { type: "appPricePoints", id: free["id"] } } }
        }]
      })
      say "App price set to Free."
    end

    # Makes the app available in every country (set EXCLUDE_EU=1 to skip the EU,
    # e.g. if you have not filled in the EU Digital Services Act trader status yet).
    def set_app_availability(app_id, exclude_eu: false)
      if get_or_nil("/v1/apps/#{app_id}/appAvailabilityV2").to_h["data"]
        say "App availability already set."
        return
      end

      territories = territory_ids
      territories -= EU_TERRITORIES if exclude_eu
      included = territories.map do |t|
        { type: "territoryAvailabilities", id: "${#{t}}",
          attributes: { available: true },
          relationships: { territory: { data: { type: "territories", id: t } } } }
      end
      post("/v2/appAvailabilities", {
        data: {
          type: "appAvailabilities",
          attributes: { availableInNewTerritories: !exclude_eu },
          relationships: {
            app: { data: { type: "apps", id: app_id } },
            territoryAvailabilities: { data: included.map { |i| { type: i[:type], id: i[:id] } } }
          }
        },
        included: included
      })
      say "App available in #{territories.size} countries/regions."
    end

    # Fills in the age rating questionnaire (all "None"/"No" => 4+).
    def set_age_rating(app_id)
      infos = get("/v1/apps/#{app_id}/appInfos")["data"]
      info = infos.find { |i| i.dig("attributes", "state") != "READY_FOR_DISTRIBUTION" } || infos.first
      raise Error, "No appInfo found for the app." unless info

      decl = get("/v1/appInfos/#{info['id']}/ageRatingDeclaration")["data"]
      attrs = AGE_RATING_NONE.dup
      known = decl["attributes"].to_h.keys
      attrs.select! { |k, _| known.empty? || known.include?(k) }

      5.times do
        begin
          patch("/v1/ageRatingDeclarations/#{decl['id']}",
                data: { type: "ageRatingDeclarations", id: decl["id"], attributes: attrs })
          break
        rescue Error => e
          # Apple sometimes renames questions. Drop any field it rejects and try again.
          bad = e.errors.map { |er| er.dig("source", "pointer").to_s[%r{/data/attributes/(\w+)}, 1] }.compact
          raise if bad.empty?

          say "Age rating: Apple rejected #{bad.join(', ')}; retrying without them."
          bad.each { |b| attrs.delete(b) }
        end
      end

      after = get("/v1/ageRatingDeclarations/#{decl['id']}")["data"]["attributes"].to_h
      missing = after.select { |k, v| v.nil? && !AGE_RATING_SKIP.include?(k) }.keys
      if missing.empty?
        say "Age rating questionnaire filled in (expected result: 4+)."
      else
        say "Age rating: these NEW questions still need an answer on the website: #{missing.join(', ')}"
      end
    end

    # ---------------------------------------------------------------- In-App Purchase

    # Creates or updates the non-consumable IAP and returns its data (incl. attributes.state).
    def ensure_iap(app_id, product_id:, reference_name:, display_name:, description:,
                   review_note:, price: "0.99", review_screenshot: nil)
      iap = find_iap(app_id, product_id)
      if iap
        say "In-App Purchase #{product_id} exists (state: #{iap.dig('attributes', 'state')})."
      else
        iap = post("/v2/inAppPurchases", data: {
          type: "inAppPurchases",
          attributes: {
            name: reference_name,
            productId: product_id,
            inAppPurchaseType: "NON_CONSUMABLE",
            reviewNote: review_note,
            familySharable: false
          },
          relationships: { app: { data: { type: "apps", id: app_id } } }
        })["data"]
        say "Created In-App Purchase #{product_id}."
      end
      iap_id = iap["id"]

      ensure_iap_localization(iap_id, display_name, description)
      ensure_iap_availability(iap_id)
      ensure_iap_price(iap_id, price)
      ensure_iap_review_screenshot(iap_id, review_screenshot) if review_screenshot

      find_iap(app_id, product_id)
    end

    def find_iap(app_id, product_id)
      get_all("/v1/apps/#{app_id}/inAppPurchasesV2", "filter[productId]" => product_id, "limit" => 50)
        .find { |i| i.dig("attributes", "productId") == product_id }
    end

    def ensure_iap_localization(iap_id, name, description)
      locs = get_all("/v2/inAppPurchases/#{iap_id}/inAppPurchaseLocalizations")
      if locs.any? { |l| l.dig("attributes", "locale") == "en-US" }
        say "IAP English name/description already set."
        return
      end

      post("/v1/inAppPurchaseLocalizations", data: {
        type: "inAppPurchaseLocalizations",
        attributes: { locale: "en-US", name: name, description: description },
        relationships: { inAppPurchaseV2: { data: { type: "inAppPurchases", id: iap_id } } }
      })
      say "IAP English name/description added."
    end

    def ensure_iap_availability(iap_id)
      if get_or_nil("/v2/inAppPurchases/#{iap_id}/inAppPurchaseAvailability").to_h["data"]
        say "IAP availability already set."
        return
      end

      post("/v1/inAppPurchaseAvailabilities", data: {
        type: "inAppPurchaseAvailabilities",
        attributes: { availableInNewTerritories: true },
        relationships: {
          inAppPurchase: { data: { type: "inAppPurchases", id: iap_id } },
          availableTerritories: { data: territory_ids.map { |t| { type: "territories", id: t } } }
        }
      })
      say "IAP available in all countries/regions."
    end

    def ensure_iap_price(iap_id, price)
      schedule = get_or_nil("/v2/inAppPurchases/#{iap_id}/iapPriceSchedule", "include" => "manualPrices")
      if schedule && Array(schedule["included"]).any?
        current = current_iap_prices(schedule.dig("data", "id"))
        if current.include?(format("%.2f", price.to_f))
          say "IAP price already set to $#{price}."
          return
        end
        say "IAP price is #{current.empty? ? 'unknown' : '$' + current.join('/')}; changing it to $#{price}."
      end

      point = get_all("/v2/inAppPurchases/#{iap_id}/pricePoints", "filter[territory]" => "USA", "limit" => 200)
              .find { |p| format("%.2f", p.dig("attributes", "customerPrice").to_f) == format("%.2f", price.to_f) }
      raise Error, "Could not find a US price point of $#{price}." unless point

      post("/v1/inAppPurchasePriceSchedules", {
        data: {
          type: "inAppPurchasePriceSchedules",
          relationships: {
            inAppPurchase: { data: { type: "inAppPurchases", id: iap_id } },
            baseTerritory: { data: { type: "territories", id: "USA" } },
            manualPrices: { data: [{ type: "inAppPurchasePrices", id: "${price1}" }] }
          }
        },
        included: [{
          type: "inAppPurchasePrices", id: "${price1}",
          attributes: { startDate: nil },
          relationships: {
            inAppPurchaseV2: { data: { type: "inAppPurchases", id: iap_id } },
            inAppPurchasePricePoint: { data: { type: "inAppPurchasePricePoints", id: point["id"] } }
          }
        }]
      })
      say "IAP price set to $#{price} (other countries follow Apple's automatic equivalents)."
    end

    # US prices (as "0.99" strings) in the IAP's current manual price schedule.
    def current_iap_prices(schedule_id)
      return [] if schedule_id.to_s.empty?

      res = get("/v1/inAppPurchasePriceSchedules/#{schedule_id}/manualPrices",
                "include" => "inAppPurchasePricePoint,territory", "filter[territory]" => "USA")
      Array(res["included"]).select { |i| i["type"] == "inAppPurchasePricePoints" }
                            .map { |i| format("%.2f", i.dig("attributes", "customerPrice").to_f) }
    rescue Error
      []
    end

    # Uploads the screenshot App Review sees for the IAP (the Pro screen).
    def ensure_iap_review_screenshot(iap_id, path)
      raise Error, "Review screenshot not found: #{path}" unless File.exist?(path)

      current = get_or_nil("/v2/inAppPurchases/#{iap_id}/appStoreReviewScreenshot").to_h["data"]
      state = current&.dig("attributes", "assetDeliveryState", "state")
      if current && %w[COMPLETE UPLOAD_COMPLETE].include?(state)
        say "IAP review screenshot already uploaded."
        return
      end

      bytes = File.binread(path)
      reservation = post("/v1/inAppPurchaseAppStoreReviewScreenshots", data: {
        type: "inAppPurchaseAppStoreReviewScreenshots",
        attributes: { fileSize: bytes.bytesize, fileName: File.basename(path) },
        relationships: { inAppPurchaseV2: { data: { type: "inAppPurchases", id: iap_id } } }
      })["data"]

      Array(reservation.dig("attributes", "uploadOperations")).each do |op|
        uri = URI(op["url"])
        req = Net::HTTPGenericRequest.new(op["method"], true, true, uri.request_uri)
        Array(op["requestHeaders"]).each { |h| req[h["name"]] = h["value"] }
        req.body = bytes.byteslice(op["offset"].to_i, op["length"].to_i)
        res = Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |http| http.request(req) }
        raise Error.new("Screenshot upload failed (HTTP #{res.code})", status: res.code.to_i) unless res.code.to_i.between?(200, 299)
      end

      patch("/v1/inAppPurchaseAppStoreReviewScreenshots/#{reservation['id']}", data: {
        type: "inAppPurchaseAppStoreReviewScreenshots", id: reservation["id"],
        attributes: { uploaded: true, sourceFileChecksum: Digest::MD5.hexdigest(bytes) }
      })
      say "IAP review screenshot uploaded."
    end

    # ---------------------------------------------------------------- status

    # Read-only report for `make status` and `make doctor`.
    # Returns [exit_code, text]. 0 = app exists, 2 = key works but no app yet.
    def status_report(bundle_id)
      lines = []
      app = find_app(bundle_id)
      lines << "API key works."
      bundle = get_all("/v1/bundleIds", "filter[identifier]" => bundle_id, "limit" => 5)
               .find { |b| b.dig("attributes", "identifier") == bundle_id }
      lines << if bundle
                 "Bundle ID #{bundle_id}: registered."
               else
                 "Bundle ID #{bundle_id}: not registered yet."
               end
      if app.nil?
        lines << "App record: not created yet."
        lines << "IAP: not created"
        lines << "TestFlight: no build yet."
        return [2, lines.join("\n")]
      end

      lines << "App: #{app.dig('attributes', 'name')} (id #{app['id']})"
      versions = app_store_versions(app["id"])
      if versions.empty?
        lines << "App Store version: none yet."
      else
        versions.first(3).each do |version|
          number = version.dig("attributes", "versionString")
          state = version.dig("attributes", "appStoreState").to_s.tr("_", " ")
          lines << "Version #{number}: #{state}"
        end
      end

      builds = recent_builds(app["id"])
      if @build_error
        lines << "TestFlight: could not list builds (#{@build_error})."
      elsif builds.empty?
        lines << "TestFlight: no build yet. The next upload will be build 1."
      else
        latest = builds.first
        number = latest.dig("attributes", "version")
        state = latest.dig("attributes", "processingState").to_s
        label = {
          "PROCESSING" => "processing",
          "VALID" => "ready",
          "FAILED" => "failed",
          "INVALID" => "invalid"
        }[state] || state
        lines << "Latest TestFlight build: #{number} (#{label})."
        lines << "Next upload will use build #{number.to_i + 1}."
      end

      iap = find_iap(app["id"], "com.krishnav.SoleCount.pro")
      lines << if iap
                 "IAP: #{iap.dig('attributes', 'state')}"
               else
                 "IAP: not created"
               end
      live = live_version(app["id"])
      lines << if live
                 "On the App Store: version #{live.dig('attributes', 'versionString')} is live."
               else
                 "On the App Store: not yet."
               end
      [0, lines.join("\n")]
    end

    def app_store_versions(app_id)
      get("/v1/apps/#{app_id}/appStoreVersions",
          "filter[platform]" => "IOS", "limit" => 5)["data"]
    rescue Error => e
      say "Could not list App Store versions (#{e.message})."
      []
    end

    def recent_builds(app_id)
      get("/v1/builds", "filter[app]" => app_id, "sort" => "-uploadedDate", "limit" => 3)["data"]
    rescue Error => e
      @build_error = e.message
      []
    end

    # ---------------------------------------------------------------- helpers

    EU_TERRITORIES = %w[AUT BEL BGR HRV CYP CZE DNK EST FIN FRA DEU GRC HUN IRL ITA LVA LTU LUX
                        MLT NLD POL PRT ROU SVK SVN ESP SWE].freeze

    def territory_ids
      @territory_ids ||= get_all("/v1/territories", "limit" => 200).map { |t| t["id"] }
    end

    private

    def say(message)
      @log&.call("[ASC] #{message}")
    end

    def b64url(data)
      Base64.urlsafe_encode64(data, padding: false)
    end

    def build_uri(path, query)
      uri = URI(path.start_with?("http") ? path : BASE + path)
      uri.query = URI.encode_www_form(query) unless query.nil? || query.empty?
      uri
    end

    def request_uri(method, uri, body = nil, attempt: 1)
      klass = { get: Net::HTTP::Get, post: Net::HTTP::Post, patch: Net::HTTP::Patch }.fetch(method)
      req = klass.new(uri)
      req["Authorization"] = "Bearer #{token}"
      req["Accept"] = "application/json"
      if body
        req["Content-Type"] = "application/json"
        req.body = JSON.generate(body)
      end
      res = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 30, read_timeout: 120) do |http|
        http.request(req)
      end

      code = res.code.to_i
      if (code == 429 || code >= 500) && attempt < 4
        sleep(2**attempt)
        return request_uri(method, uri, body, attempt: attempt + 1)
      end
      return (res.body.to_s.empty? ? {} : JSON.parse(res.body)) if code.between?(200, 299)

      errors = begin
        Array(JSON.parse(res.body.to_s)["errors"])
      rescue JSON::ParserError
        []
      end
      details = errors.map { |e| [e["title"], e["detail"]].compact.join(": ") }.join(" | ")
      hint = case code
             when 401 then " (check ASC_KEY_ID, ASC_ISSUER_ID and the .p8 file)"
             when 403 then " (the API key needs the Admin role, and all agreements must be accepted)"
             else ""
             end
      raise Error.new("#{method.upcase} #{uri.path} failed: HTTP #{code}#{hint}. #{details}", status: code, errors: errors)
    end
  end
end

# ------------------------------------------------------------------ command line
if $PROGRAM_NAME == __FILE__
  begin
    bundle_id = ENV.fetch("APP_IDENTIFIER", "com.krishnav.SoleCount")
    client = SoleCountASC::Client.from_env
    case ARGV.first
    when "status", nil
      code, text = client.status_report(bundle_id)
      puts text
      exit code
    when "token"
      puts client.token
    else
      warn "Usage: ruby fastlane/asc_api.rb [status|token]"
      exit 1
    end
  rescue SoleCountASC::Error => e
    warn e.message
    exit 1
  rescue OpenSSL::PKey::PKeyError
    warn "The .p8 file could not be read as a private key."
    exit 1
  end
end
