# frozen_string_literal: true

module FDroid
  class Utils
    # Given the desired_locale, searches through the list of localized_data entries
    # and finds those with keys which match either:
    #  * The desired locale exactly
    #  * The same language as the desired locale (but different region)
    #  * Any English language (so if the desired language is not there it will suffice)
    #
    # These will be sorted in order of preference:
    #  * Special handling when the desired locale is en: prefer en-US
    #  * Exact matches (language and region)
    #  * Language portion matches and region matches an "alias" (e.g. zh_Hant and zh-TW).
    #  * Language portion matches but region is absent/doesn't match.
    #  * en-US
    #  * en
    #  * en-*
    #
    # It is intentionally liberal in searching for either "_" or "-" to separate language
    # and region, because they both mean (in different context) to split langugae on the
    # left, and region on the right, and it is cheap to do so.
    #
    # @param [string]  desired_locale
    # @param [Hash]  localized_data
    # @return [Array]
    def self.available_locales(desired_locale, localized_data)
      # website uses zh_Hant/zh_Hans, but zh-TW/zh-CN are common in localized data
      aliases = { 'zh' => { 'Hant' => ['TW'], 'Hans' => ['CN'] } }

      parts = desired_locale.split(/[_-]/)
      desired_lang = parts[0]
      desired_region = parts.length > 1 ? parts[1] : nil

      locales = localized_data.keys.select do |available_locale|
        parts = available_locale.split(/[_-]/)
        available_lang = parts[0]
        available_lang == desired_lang || available_lang == 'en'
      end

      measure_locale_goodness = lambda do |locale|
        parts = locale.split(/[_-]/)
        lang = parts[0]
        region = parts.length > 1 ? parts[1] : nil
        if desired_locale == 'en' && locale == 'en-US'
          return 1
        elsif locale == desired_locale
          return 2
        elsif lang == desired_lang
          if aliases.fetch(lang, {}).fetch(desired_region, []).include?(region)
            return 3
          else
            return 4
          end
        elsif locale == 'en-US'
          return 5
        elsif locale == 'en'
          return 6
        elsif lang == 'en'
          return 7
        end
      end

      locales.sort do |a, b|
        measure_locale_goodness.call(a) <=> measure_locale_goodness.call(b)
      end
    end

    # Any transformations which are required to turn the "description" into something which is
    # displayable via HTML is done here (e.g. replacing "fdroid.app:" schemes, formatting new lines,
    # etc.
    def self.process_package_description(string)
      return nil if string == nil

      format_description_to_html(replace_fdroid_app_links(strip_lang_from_app_links(string)))
    end

    # https://f-droid.org/ru/packages/org.fdroid.fdroid/ -> https://f-droid.org/packages/org.fdroid.fdroid/
    # https://f-droid.org/zh_Hans/packages/org.fdroid.fdroid/ -> https://f-droid.org/packages/org.fdroid.fdroid/
    # @param [string]  string
    # @return [string]
    def self.strip_lang_from_app_links(string)
      string.gsub(
        /https:\/\/f-droid\.org\/[^\/]+\/packages\//,
        'https://f-droid.org/packages/'
      )
    end

    # Finds all https://f-droid.org/packages/ links that end with an Application ID, and
    # replaces them with an HTML link.
    # @param [string]  string
    # @return [string]
    def self.replace_fdroid_app_links(string)
      string.gsub(/fdroid\.app:([a-zA-Z0-9._]+)/,
                  '<a href="/packages/\1/"><tt>\1</tt></a>')
            .gsub(/([^">])(https:\/\/f-droid\.org\/packages\/)((?:[a-zA-Z_]+(?:\d*[a-zA-Z_]*)*)(?:\.[a-zA-Z_]+(?:\d*[a-zA-Z_]*)*)*)\/?/,
                  '\1<a href="\2\3/"><tt>\3</tt></a>')
    end

    # Ensure newlines in descriptions are preserved (converted to "<br>" tags)
    # Handles UNIX, Windows and MacOS newlines, with a one-to-one replacement
    def self.format_description_to_html(string)
      Loofah.fragment(string)
            .scrub!(:strip)
            .scrub!(:fdroid)
            .to_html(:save_with => 0)
            .gsub(/(?:\n\r?|\r\n?)/, '<br>')
    end

    ESCAPES = {
      '<' => '&lt;', '>' => '&gt;', '"' => '&quot;', "'" => '&#x27;', '&' => '&amp;'
    }

    # used to recursively sanitise the hash returned by to_data, except for any
    # data already passed through process_package_description (and thus scrubbed
    # by loofah)
    def self.sanitise(value, skip = [], skip_recursive = false)
      case value
      when String
        value.gsub(/[<>"'&]/, ESCAPES)
      when Hash
        value.map { |k, v| skip.include?(k) ? [k, v] : [k, skip_recursive && skip && !skip.empty? ? sanitise(v, skip, skip_recursive) : sanitise(v)] }.to_h
      when Array
        value.map { |x| skip_recursive && skip && !skip.empty? ? sanitise(x, skip, skip_recursive) : sanitise(x) }
      when Date, Float, Integer, nil
        value
      else
        raise "cannot sanitise #{value.inspect}"
      end
    end
  end
end
