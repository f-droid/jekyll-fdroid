require 'rspec'
require 'pp'
require 'json'
require_relative '../../../lib/fdroid/IndexV1'
require_relative '../../../lib/fdroid/App'

module FDroid
  RSpec.describe App do

    path = File.expand_path '../../assets/localized.json', File.dirname(__FILE__)
    localized = JSON.parse(File.read(path))

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
    end

  end

  RSpec.describe Permission do
    it 'Serializes in a sane manner' do
      permission = Permission.new(["my-permission", nil]).to_data
      expect(permission).to eql({"permission"=>"my-permission", "min_sdk"=>nil})

      package = Package.new({
        "uses-permission"=>[
          ["perm1", nil],
          ["perm2", 24]
        ]
      }).to_data

      expect(package['uses_permission']).to eql([
        {"permission"=>"perm1", "min_sdk"=>nil},
        {"permission"=>"perm2", "min_sdk"=>24},
      ])
    end
  end

  RSpec.describe IndexV1 do
    it 'Downloads and extracts jar files', :network => true do
      repo = 'https://guardianproject.info/fdroid/repo'
      index = FDroid::IndexV1.download(repo, 'en_US')
      expect(index.apps.count).to eql(10)
    end

    it 'Parses the Guardian Project repo metadata correctly' do

    end

    it 'Processes the F-Droid repo metadata correctly' do
      path = File.expand_path '../../assets/index-v1.json', File.dirname(__FILE__)
      index_json = JSON.parse(File.read(path))
      index = FDroid::IndexV1.new(index_json, 'en_US')
      expect(index.apps.count).to eql(1246)

      # Force each app to parse itself and make sure it doesn't crash.
      index.apps.each { |app| app.to_data }

      fdroid = index.apps.detect { |app| app.package_name == 'org.fdroid.fdroid' }.to_data
      fdroid_package = fdroid['packages'][0]
      fdroid['packages'] = nil

      expected_package = {
          "version_name"=>"1.0-alpha0",
          "version_code"=>1000000,
          "added"=>Date.new(2017, 7, 9),
          "apk_name"=>"org.fdroid.fdroid_1000000.apk",
          "hash"=>"bbbbd10bf93c8f670cc869e1f2a148b83821c80b566d0a1b7858b26b7a3660fa",
          "hash_type"=>"sha256",
          "min_sdk_version"=>"10",
          "max_sdk_version"=>nil,
          "target_sdk_version"=>"24",
          "native_code"=>nil,
          "sig"=>"9063aaadfff9cfd811a9c72fb5012f28",
          "size"=>7135159,
          "uses_permission"=>[
            {"permission"=>"android.permission.INTERNET", "min_sdk"=>nil},
            {"permission"=>"android.permission.ACCESS_NETWORK_STATE", "min_sdk"=>nil},
            {"permission"=>"android.permission.ACCESS_WIFI_STATE", "min_sdk"=>nil},
            {"permission"=>"android.permission.CHANGE_WIFI_MULTICAST_STATE", "min_sdk"=>nil},
            {"permission"=>"android.permission.CHANGE_NETWORK_STATE", "min_sdk"=>nil},
            {"permission"=>"android.permission.CHANGE_WIFI_STATE", "min_sdk"=>nil},
            {"permission"=>"android.permission.BLUETOOTH", "min_sdk"=>nil},
            {"permission"=>"android.permission.BLUETOOTH_ADMIN", "min_sdk"=>nil},
            {"permission"=>"android.permission.RECEIVE_BOOT_COMPLETED", "min_sdk"=>nil},
            {"permission"=>"android.permission.WRITE_EXTERNAL_STORAGE", "min_sdk"=>nil},
            {"permission"=>"android.permission.WRITE_SETTINGS", "min_sdk"=>nil},
            {"permission"=>"android.permission.NFC", "min_sdk"=>nil},
            {"permission"=>"android.permission.ACCESS_SUPERUSER", "min_sdk"=>nil},
            {"permission"=>"android.permission.READ_EXTERNAL_STORAGE", "min_sdk"=>nil}
          ]
      }

      expected_app = {
          "package_name"=>"org.fdroid.fdroid",
          "author_email"=>nil,
          "author_name"=>nil,
          "author_website"=>nil,
          "bitcoin"=>"15u8aAPK4jJ5N8wpWJ5gutAyyeHtKX5i18",
          "donate"=>"https://f-droid.org/about",
          "flattr"=>nil,
          "categories"=>["System"],
          "anti_features"=>nil,
          "suggested_version_code"=>"102350",
          "issue_tracker"=>"https://gitlab.com/fdroid/fdroidclient/issues",
          "changelog"=>"https://gitlab.com/fdroid/fdroidclient/raw/HEAD/CHANGELOG.md",
          "license"=>"GPL-3.0+",
          "source_code"=>"https://gitlab.com/fdroid/fdroidclient",
          "website"=>"https://f-droid.org",
          "added"=>1295222400000,
          "last_updated"=>1499583764677,
          "icon"=>"icons-640/org.fdroid.fdroid.1000000.png",
          "title"=>"F-Droid",
          "summary"=>"The app store that respects freedom and privacy\n",
          "description"=>
              "F-Droid is an installable catalogue of FOSS (Free and Open Source\n" +
              "Software) applications for the Android platform. The client makes it\n" +
              "easy to browse, install, and keep track of updates on your device.\n" +
              "\n" +
              "It connects to any F-Droid compatible repositories. The default repo\n" +
              "is hosted at f-droid.org, which contains only bona fide Free and Open\n" +
              "Source Software.\n" +
              "\n" +
              "Android itself is open in the sense that you are free to install apks\n" +
              "from anywhere you wish, but there are many good reasons for using\n" +
              "F-Droid as your free software app manager:\n" +
              "\n" +
              "* Be notified when updates are available\n" +
              "* optionally download and install updates automatically\n" +
              "* Keep track of older and beta versions\n" +
              "* Filter apps that aren't compatible with the device\n" +
              "* Find apps via categories and searchable descriptions\n" +
              "* Access associated urls for donations, source code etc.\n" +
              "* Stay safe by checking repo index signatures and apk hashes\n",
          "feature_graphic"=>nil,
          "phone_screenshots"=>nil,
          "seven_inch_screenshots"=>nil,
          "packages"=>nil,
          "beautiful_url"=>"/packages/org.fdroid.fdroid"
      }


      expect(fdroid).to eql(expected_app)
      expect(fdroid_package).to eql(expected_package)
    end

  end
end
