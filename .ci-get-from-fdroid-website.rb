#!/usr/bin/ruby
#
# This parses fdroid/fdroid-website's .gitlab-ci.yml and outputs the
# selected bits to be piped to bash for execution in a CI job.

require 'yaml'

d = YAML.load_file('.gitlab-ci.yml', aliases: true)
puts d['.apt-template'].gsub(/\\\n/, ' ')
puts d['.setup_for_jekyll'].gsub(/\\\n/, ' ')
