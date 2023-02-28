require 'rspec'
require 'liquid'
require 'jekyll'
require_relative '../../../lib/jekyll/FDroidRepoMirrorsTag'

module Jekyll
  RSpec.describe FDroidRepoMirrorsTag do
    def make_context
      Liquid::Context.new(
        {},
        {},
        {
          :site => Jekyll::Site.new(
            {
              'source' => '/tmp',
              'destination' => '/tmp/build',
              'permalink' => '',
              'liquid' => {
                'error_mode' => ''
              },
              'limit_posts' => 0,
              'plugins' => [],
              'kramdown' => {},
              'fdroid-repo' => 'https://guardianproject.info/fdroid/repo'
            }
          )
        }
      )
    end

    it 'renders fdroid_repo_mirrors correctly', { :network => true, :tag => true } do
      template = Liquid::Template.parse('{% fdroid_repo_mirrors %}').render make_context
      puts template
      expect(template).to match(/<table><tbody><tr><td><tt>https:\/\/s3.amazonaws.com\/guardianproject\/fdroid\/repo<\/tt><\/td><\/tr><tr><td><tt>https:\/\/guardianproject.s3.amazonaws.com\/fdroid\/repo<\/tt><\/td><\/tr><\/tbody><\/table>/)
    end
  end
end
