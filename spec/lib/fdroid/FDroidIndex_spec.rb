# coding: utf-8

require 'rspec'
require 'pp'
require 'json'
require_relative '../../../lib/fdroid/IndexV1'
require_relative '../../../lib/fdroid/App'

module FDroid
  RSpec.describe App do
    localized_path = File.expand_path '../../assets/localized.json', File.dirname(__FILE__)
    localized = JSON.parse(File.read(localized_path))

    gp_path = File.expand_path '../../assets/index-v1.gp.json', File.dirname(__FILE__)
    gp_json = JSON.parse(File.read(gp_path))

    it 'Decides which locales to use' do
      de_locales = App.available_locales('de-DE', localized)
      expect(de_locales).to eq(['de-DE', 'de', 'de-AT', 'en-US', 'en', 'en-AU'])

      fr_locales = App.available_locales('fr-FR', localized)
      expect(fr_locales).to eq(['fr-CA', 'en-US', 'en', 'en-AU'])

      en_locales = App.available_locales('en', localized)
      expect(en_locales).to eq(['en', 'en-US', 'en-AU'])

      zh_locales = App.available_locales('zh', localized)
      expect(zh_locales).to eq(['en-US', 'en', 'en-AU'])
    end

    it 'Calculates localized metadata correctly' do
      de_locales = App.available_locales('de-DE', localized)

      name = App.localized(de_locales, localized, 'name')
      expect(name).to eql('App [de-DE]')

      feature_graphic = App.localized_graphic_path(de_locales, localized, 'featureGraphic')
      expect(feature_graphic).to eql('de-DE/Feature Graphic [de-DE].png')

      phone_screenshots = App.localized_graphic_list_paths(de_locales, localized, 'phoneScreenshots')
      expect(phone_screenshots).to eql(
        [
          'de-DE/phoneScreenshots/Phone 1 [de-DE].jpg',
          'de-DE/phoneScreenshots/Phone 2 [de-DE].jpg',
        ]
      )
    end

    it 'Formats app descriptions correctly' do
      text = "This
is
a

multi-line

string
here"
      multi_line = App.format_description_to_html(text)
      expect(multi_line).to eql("This<br />is<br />a<br /><br />multi-line<br /><br />string<br />here")
    end
  end

  RSpec.describe Permission do
    it 'Serializes in a sane manner' do
      permission = Permission.new(["my-permission", nil]).to_data
      expect(permission).to eql({ "permission" => "my-permission", "min_sdk" => nil })

      package = Package.new(
        {
          "uses-permission" =>
          [
            ["perm1", nil],
            ["perm2", 24]
          ]
        }
      ).to_data

      expect(package['uses_permission']).to eql(
        [
          { "permission" => "perm1", "min_sdk" => nil },
          { "permission" => "perm2", "min_sdk" => 24 },
        ]
      )
    end
  end

  RSpec.describe IndexV1 do
    it 'Downloads and extracts jar files', :network => true do
      repo = 'https://guardianproject.info/fdroid/repo'
      index = FDroid::IndexV1.download(repo, 'en_US')
      expect(index.apps.count).to be >= 10
    end

    def parse_checkey_from_gp(locale)
      path = File.expand_path '../../assets/index-v1.gp.json', File.dirname(__FILE__)
      index_json = JSON.parse(File.read(path))
      index = FDroid::IndexV1.new(index_json, locale)

      expect(index.repo.name).to eql('Guardian Project Official Releases')
      expect(index.repo.address).to eql('https://guardianproject.info/fdroid/repo')
      expect(index.repo.icon_url).to eql('https://guardianproject.info/fdroid/repo/icons/guardianproject.png')
      expect(index.repo.date).to eql(Date.new(2017, 07, 19))
      expect(index.repo.description).to eql(
        'The official app repository of The Guardian Project. Applications in ' +
        'this repository are official binaries build by the original ' +
        'application developers and signed by the same key as the APKs that ' +
        'are released in the Google Play store. '
      )

      expect(index.apps.count).to eql(11)

      # Force each app to parse itself and make sure it doesn't crash.
      index.apps.each { |app| app.to_data }

      # Then return Checkey when we know that each app is able to be parsed.
      index.apps.detect { |app| app.package_name == 'info.guardianproject.checkey' }
    end

    def parse_camerav_from_gp(locale)
      path = File.expand_path '../../assets/index-v1.gp.json', File.dirname(__FILE__)
      index_json = JSON.parse(File.read(path))
      index = FDroid::IndexV1.new(index_json, locale)
      index.apps.detect { |app| app.package_name == 'org.witness.informacam.app' }
    end

    def parse_loofah_test_from_gp()
      path = File.expand_path '../../assets/index-v1.gp.json', File.dirname(__FILE__)
      index_json = JSON.parse(File.read(path))
      index = FDroid::IndexV1.new(index_json, 'en_US')
      index.apps.detect { |app| app.package_name == 'loofah.test' }
    end

    it 'Loofah runs on all text fields that can be rendered with HTML' do
      loofah_test = parse_loofah_test_from_gp().to_data
      expect(loofah_test['description']).to eq("This is just a test that &lt;script&gt;alert('pwned!')&lt;/script&gt; loofah is stripping.")
      expect(loofah_test['summary']).to eq("트리거 불안에 때 개인 정보를 보호하거나 상황을 패닉 앱&lt;script&gt;alert('pwned!')&lt;/script&gt;")
      expect(loofah_test['title']).to eq("&lt;script&gt;alert('PWN!')&lt;/script&gt;")
      expect(loofah_test['whats_new']).to eq("Feature:<br />* Add support for packs (@Rudloff)<br />&lt;script&gt;alert('pwned!')&lt;/script&gt;<br />Minor:<br />* Change name to Launcher<br />")
    end

    it 'Parses the Guardian Project repo metadata correctly' do
      checkey_en_US = parse_checkey_from_gp('en_US').to_data
      checkey_en_AU = parse_checkey_from_gp('en_AU').to_data
      checkey_en = parse_checkey_from_gp('en').to_data
      checkey_unknown = parse_checkey_from_gp('unknown locale').to_data

      expect(checkey_en_US).to eql(checkey_en_AU)
      expect(checkey_en_US).to eql(checkey_en)
      expect(checkey_en_US).to eql(checkey_unknown)

      checkey_fi = parse_checkey_from_gp('fi').to_data

      expect(checkey_en_US).not_to eql(checkey_fi)
      expect(checkey_en_US['title']).not_to eq(checkey_fi['title'])
      expect(checkey_en_US['summary']).not_to eq(checkey_fi['summary'])
      expect(checkey_en_US['description']).not_to eq(checkey_fi['description'])

      expect(checkey_en_US['phone_screenshots'].length).to eq(5)
    end

    it 'Follows proper override rules for name/summary/description' do
      camerav_en_US = parse_camerav_from_gp('en_US').to_data
      camerav_th = parse_camerav_from_gp('th').to_data

      expect(camerav_en_US['title']).to eq(camerav_th['title'])
      expect(camerav_en_US['summary']).to eq(camerav_th['summary'])
      expect(camerav_en_US['description']).to eq(camerav_th['description'])
    end

    it 'Processes the F-Droid repo metadata correctly' do
      path = File.expand_path '../../assets/index-v1.json', File.dirname(__FILE__)
      index_json = JSON.parse(File.read(path))
      index = FDroid::IndexV1.new(index_json, 'en_US')

      expect(index.repo.name).to eql('F-Droid')
      expect(index.repo.address).to eql('https://f-droid.org/repo')
      expect(index.repo.icon_url).to eql('https://f-droid.org/repo/icons/fdroid-icon.png')
      expect(index.repo.date).to eql(Date.new(2018, 12, 27))
      expect(index.repo.description).to eql(
        'The official FDroid repository. Applications in this repository are ' +
        'built directly from the source code. (One, Firefox, is the official ' +
        'binary built by the Mozilla. This will ultimately be replaced by a ' +
        'source-built version. '
      )

      expect(index.apps.count).to eql(1717)

      # Force each app to parse itself and make sure it doesn't crash.
      index.apps.each { |app| app.to_data }

      fdroid = index.apps.detect { |app| app.package_name == 'org.fdroid.fdroid' }.to_data

      # Assert that packages are ordered in reverse-chronological order
      expect(fdroid['packages'].map { |p| p['version_code'] }).to eql([1005050, 1005002, 1005001, 1005000, 1004050, 1004001, 1004000, 1003051, 1003050, 1003005, 1003004, 1003003])

      fdroid_package = fdroid['packages'][0]
      fdroid['packages'] = nil # remove packages for later app test

      expected_package = {
        "added" => Date.new(2018, 12, 27),
        "anti_features" => nil,
        "apk_name" => "org.fdroid.fdroid_1005050.apk",
        "file_extension" => "APK",
        "hash" => "edbabb5d76bbb509151f4cdbbc1f340a095e169b41838f4619ecb0b10ea702c8",
        "hash_type" => "sha256",
        "min_sdk_version" => "14",
        "max_sdk_version" => nil,
        "target_sdk_version" => "25",
        "nativecode" => nil,
        "srcname" => "org.fdroid.fdroid_1005050_src.tar.gz",
        "sig" => "9063aaadfff9cfd811a9c72fb5012f28",
        "signer" => "43238d512c1e5eb2d6569f4a3afbf5523418b82e0a3ed1552770abb9a9c9ccab",
        "size" => 7675508,
        "uses_permission" =>
        [
          { "min_sdk" => nil, "permission" => "android.permission.INTERNET" },
          { "min_sdk" => nil, "permission" => "android.permission.ACCESS_NETWORK_STATE" },
          { "min_sdk" => nil, "permission" => "android.permission.ACCESS_WIFI_STATE" },
          { "min_sdk" => nil, "permission" => "android.permission.CHANGE_WIFI_MULTICAST_STATE" },
          { "min_sdk" => nil, "permission" => "android.permission.CHANGE_NETWORK_STATE" },
          { "min_sdk" => nil, "permission" => "android.permission.CHANGE_WIFI_STATE" },
          { "min_sdk" => nil, "permission" => "android.permission.BLUETOOTH" },
          { "min_sdk" => nil, "permission" => "android.permission.BLUETOOTH_ADMIN" },
          { "min_sdk" => nil, "permission" => "android.permission.RECEIVE_BOOT_COMPLETED" },
          { "min_sdk" => nil, "permission" => "android.permission.READ_EXTERNAL_STORAGE" },
          { "min_sdk" => nil, "permission" => "android.permission.WRITE_EXTERNAL_STORAGE" },
          { "min_sdk" => nil, "permission" => "android.permission.WRITE_SETTINGS" },
          { "min_sdk" => nil, "permission" => "android.permission.NFC" },
          { "min_sdk" => nil, "permission" => "android.permission.WAKE_LOCK" }
        ],
        "version_name" => "1.5",
        "version_code" => 1005050,
      }

      expected_app = {
        "package_name" => "org.fdroid.fdroid",
        "author_email" => nil,
        "author_name" => nil,
        "author_website" => nil,
        "bitcoin" => "15u8aAPK4jJ5N8wpWJ5gutAyyeHtKX5i18",
        "litecoin" => nil,
        "openCollective" => "f-droid-testing",
        "donate" => "https://f-droid.org/about",
        "flattrID" => "343053",
        "categories" => ["System"],
        "anti_features" => nil,
        "suggested_version_code" => 1004050,
        "suggested_version_name" => "1.4",
        "issue_tracker" => "https://gitlab.com/fdroid/fdroidclient/issues",
        "translation" => "https://hosted.weblate.org/projects/f-droid/f-droid",
        "changelog" => "https://gitlab.com/fdroid/fdroidclient/raw/HEAD/CHANGELOG.md",
        "license" => "GPL-3.0-or-later",
        "source_code" => "https://gitlab.com/fdroid/fdroidclient",
        "website" => "https://f-droid.org",
        "added" => 1295222400000,
        "last_updated" => 1545900545000,
        "liberapayID" => "27859",
        "icon" => "icons-640/org.fdroid.fdroid.1005050.png",
        "title" => "F-Droid",
        "whats_new" => "* huge overhaul of the \"Versions\" list in the App Details screen, and many other UI improvements, thanks to new contributor @wsdfhjxc<br /><br />* fix keyboard/d-pad navigation in many places, thanks to new contributor @doeffinger<br /><br />* show \"Open\" button when media is installed and viewable<br /><br />* add Share button to \"Installed Apps\" to export CSV list<br /><br />* add clickable list of APKs to the swap HTML index page <br /><br />* retry index downloads from mirrors<br /><br />* fix \"Send F-Droid via Bluetooth\" on recent Android versions<br />",
        "summary" => "The app store that respects freedom and privacy",
        "description" =>
        "F-Droid is an installable catalogue of FOSS (Free and Open Source<br />" +
        "Software) applications for the Android platform. The client makes it<br />" +
        "easy to browse, install, and keep track of updates on your device.<br /><br />" +
        "It connects to any F-Droid compatible repositories. The default repo<br />" +
        "is hosted at f-droid.org, which contains only bona fide Free and Open<br />" +
        "Source Software.<br /><br />" +
        "Android itself is open in the sense that you are free to install apks<br />" +
        "from anywhere you wish, but there are many good reasons for using<br />" +
        "F-Droid as your free software app manager:<br /><br />" +
        "* Be notified when updates are available<br />" +
        "* optionally download and install updates automatically<br />" +
        "* Keep track of older and beta versions<br />" +
        "* Filter apps that aren't compatible with the device<br />" +
        "* Find apps via categories and searchable descriptions<br />" +
        "* Access associated urls for donations, source code etc.<br />" +
        "* Stay safe by checking repo index signatures and apk hashes<br />",
        "feature_graphic" => "en-US/featureGraphic.jpg",
        "phone_screenshots" => [
          "en-US/phoneScreenshots/screenshot-app-details.png",
          "en-US/phoneScreenshots/screenshot-dark-details.png",
          "en-US/phoneScreenshots/screenshot-dark-home.png",
          "en-US/phoneScreenshots/screenshot-dark-knownvuln.png",
          "en-US/phoneScreenshots/screenshot-knownvuln.png",
          "en-US/phoneScreenshots/screenshot-search.png",
          "en-US/phoneScreenshots/screenshot-updates.png"
        ],
        "seven_inch_screenshots" => nil,
        "ten_inch_screenshots" => nil,
        "tv_screenshots" => nil,
        "wear_screenshots" => nil,
        "packages" => nil,
        "beautiful_url" => "/packages/org.fdroid.fdroid"
      }

      expect(fdroid).to eql(expected_app)
      expect(fdroid_package).to eql(expected_package)

      anysoftkeyboard = index.apps.detect { |app| app.package_name == 'com.menny.android.anysoftkeyboard' }.to_data
      expect(anysoftkeyboard['whats_new']).to eql("* Power-Saving mode improvements - you can pick which features to include in Power-Saving.<br />* Also, we allow switching to dark, simple theme in Power-Saving mode. But this is optional.<br />* New Workman layout, Terminal generic-top-row and long-press fixes. Done by Alex Griffin.<br />* Updated localization: AR, BE, EU, FR, HU, IT, KA, KN, KU, LT, NB, NL, PT, RO, RU, SC, UK.<br /><br />More here: https://github.com/AnySoftKeyboard/AnySoftKeyboard/milestone/87")

      subreddit = index.apps.detect { |app| app.package_name == 'subreddit.android.appstore' }.to_data
      expected_app_anti_features = [
        "NonFreeAdd",
        "NonFreeNet",
      ]
      expect(subreddit['anti_features']).to eql(expected_app_anti_features)

      droidnotify = index.apps.detect { |app| app.package_name == 'apps.droidnotify' }.to_data
      droidnotify_package = droidnotify['packages'][0]
      expected_package_anti_features = [
        "NoSourceSince"
      ]
      expect(droidnotify_package['anti_features']).to eql(expected_package_anti_features)

      perms_minsdk = index.apps.detect { |app| app.package_name == "protect.gift_card_guard" }.to_data
      perms_minsdk_package = perms_minsdk['packages'][0]

      expected_uses_permissions = [
        { "permission" => "android.permission.WRITE_EXTERNAL_STORAGE", "min_sdk" => 18 },
        { "permission" => "android.permission.READ_EXTERNAL_STORAGE", "min_sdk" => 18 },
      ]
      expect(perms_minsdk_package['uses_permission']).to eql(expected_uses_permissions)
    end
  end
end
