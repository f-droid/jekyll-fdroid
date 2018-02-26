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
      multi_line = App.format_description_to_html("This
is
a

multi-line

string
here")
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

      expect(index.apps.count).to eql(10)

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
      expect(index.repo.date).to eql(Date.new(2017, 07, 14))
      expect(index.repo.description).to eql(
        'The official FDroid repository. Applications in this repository are ' +
        'built directly from the source code. (One, Firefox, is the official ' +
        'binary built by the Mozilla. This will ultimately be replaced by a ' +
        'source-built version. '
      )

      expect(index.apps.count).to eql(1246)

      # Force each app to parse itself and make sure it doesn't crash.
      index.apps.each { |app| app.to_data }

      fdroid = index.apps.detect { |app| app.package_name == 'org.fdroid.fdroid' }.to_data

      # Assert that packages are ordered in reverse-chronological order
      expect(fdroid['packages'].map { |p| p['version_code'] }).to eql([1000000, 104050, 103250, 103150, 103050, 103003, 103002, 103001, 102350, 102250, 102150, 102050])

      fdroid_package = fdroid['packages'][0]
      fdroid['packages'] = nil

      expected_package = {
        "added" => Date.new(2017, 7, 9),
        "anti_features" => nil,
        "apk_name" => "org.fdroid.fdroid_1000000.apk",
        "file_extension" => "APK",
        "hash" => "bbbbd10bf93c8f670cc869e1f2a148b83821c80b566d0a1b7858b26b7a3660fa",
        "hash_type" => "sha256",
        "min_sdk_version" => "10",
        "max_sdk_version" => nil,
        "target_sdk_version" => "24",
        "nativecode" => nil,
        "srcname" => "org.fdroid.fdroid_1000000_src.tar.gz",
        "sig" => "9063aaadfff9cfd811a9c72fb5012f28",
        "signer" => "43238d512c1e5eb2d6569f4a3afbf5523418b82e0a3ed1552770abb9a9c9ccab",
        "size" => 7135159,
        "uses_permission" =>
        [
          { "permission" => "android.permission.INTERNET", "min_sdk" => nil },
          { "permission" => "android.permission.ACCESS_NETWORK_STATE", "min_sdk" => nil },
          { "permission" => "android.permission.ACCESS_WIFI_STATE", "min_sdk" => nil },
          { "permission" => "android.permission.CHANGE_WIFI_MULTICAST_STATE", "min_sdk" => nil },
          { "permission" => "android.permission.CHANGE_NETWORK_STATE", "min_sdk" => nil },
          { "permission" => "android.permission.CHANGE_WIFI_STATE", "min_sdk" => nil },
          { "permission" => "android.permission.BLUETOOTH", "min_sdk" => nil },
          { "permission" => "android.permission.BLUETOOTH_ADMIN", "min_sdk" => nil },
          { "permission" => "android.permission.RECEIVE_BOOT_COMPLETED", "min_sdk" => nil },
          { "permission" => "android.permission.WRITE_EXTERNAL_STORAGE", "min_sdk" => nil },
          { "permission" => "android.permission.WRITE_SETTINGS", "min_sdk" => nil },
          { "permission" => "android.permission.NFC", "min_sdk" => nil },
          { "permission" => "android.permission.ACCESS_SUPERUSER", "min_sdk" => nil },
          { "permission" => "android.permission.READ_EXTERNAL_STORAGE", "min_sdk" => nil }
        ],
        "version_name" => "1.0-alpha0",
        "version_code" => 1000000,
      }

      expected_app = {
        "package_name" => "org.fdroid.fdroid",
        "author_email" => nil,
        "author_name" => nil,
        "author_website" => nil,
        "bitcoin" => "15u8aAPK4jJ5N8wpWJ5gutAyyeHtKX5i18",
        "donate" => "https://f-droid.org/about",
        "flattrID" => "343053",
        "categories" => ["System"],
        "anti_features" => nil,
        "suggested_version_code" => 102350,
        "suggested_version_name" => "0.102.3",
        "issue_tracker" => "https://gitlab.com/fdroid/fdroidclient/issues",
        "translation" => "https://hosted.weblate.org/projects/f-droid/f-droid",
        "changelog" => "https://gitlab.com/fdroid/fdroidclient/raw/HEAD/CHANGELOG.md",
        "license" => "GPL-3.0+",
        "source_code" => "https://gitlab.com/fdroid/fdroidclient",
        "website" => "https://f-droid.org",
        "added" => 1295222400000,
        "last_updated" => 1499583764677,
        "liberapayID" => nil,
        "icon" => "icons-640/org.fdroid.fdroid.1000000.png",
        "title" => "F-Droid",
        "whats_new" => nil,
        "summary" => "The app store that respects freedom and privacy\n",
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
        "feature_graphic" => nil,
        "phone_screenshots" => nil,
        "seven_inch_screenshots" => nil,
        "packages" => nil,
        "beautiful_url" => "/packages/org.fdroid.fdroid"
      }

      expect(fdroid).to eql(expected_app)
      expect(fdroid_package).to eql(expected_package)

      antennapod = index.apps.detect { |app| app.package_name == 'de.danoeh.antennapod' }.to_data
      expect(antennapod['whats_new']).to eql(
        "* New features:<br />" +
        " * Subscription overview<br />" +
        " * Proxy support<br />" +
        " * Statistics<br />" +
        " * Manual gpodder.net sync<br />" +
        "* Fixes:<br />" +
        " * Audioplayer controls<br />" +
        " * Audio ducking<br />" +
        " * Video control fade-out<br />" +
        " * External media controls<br />" +
        " * Feed parsing"
      )
    end
  end
end
