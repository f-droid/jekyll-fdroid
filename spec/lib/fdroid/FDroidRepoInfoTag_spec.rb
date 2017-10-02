require 'rspec'
require 'liquid'
require 'jekyll'
require_relative '../../../lib/jekyll/FDroidRepoInfoTag'

module Jekyll
  RSpec.describe FDroidRepoInfoTag do
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

    it 'renders fdroid_repo_info correctly', { :network => true, :tag => true } do
      template = Liquid::Template.parse('Repo: {% fdroid_repo_info %}').render make_context
      expect(template).to match(/Repo: Guardian Project Official Releases \d\d\d\d-\d\d-\d\d/)
    end
  end
end
