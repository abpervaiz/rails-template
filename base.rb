require 'erb'
require 'ostruct'

$ruby_version = '2.3.1'
$path = File.expand_path(File.dirname(__FILE__))

$human_app_name = app_name.humanize
$class_app_name = app_name.gsub('-', '_').camelize

# -----------------------------
# HELPER FUNCTIONS
# -----------------------------
def render_file(path, variables)
  file = IO.read(path)
  struct = OpenStruct.new(variables)
  rendered_file = ERB.new(file).result(struct.instance_eval { binding })
end

# -----------------------------
# WATCHABLE LIB
# -----------------------------
# use require_dependecy to require
environment "config.watchable_dirs['lib'] = [:rb]"

# -----------------------------
# DOCUMENTATION
# -----------------------------
run 'rm readme.md'
file 'readme.md', render_file("#{$path}/files/readme.md", human_app_name: $human_app_name)

# -----------------------------
# GEMFILE
# -----------------------------
insert_into_file 'Gemfile', "\nruby '#{$ruby_version}'",
                 after: "source 'https://rubygems.org'\n"

gsub_file 'Gemfile', /^gem\s+["']sdoc["'].*$/,''
gsub_file 'Gemfile', /^gem\s+["']web-console["'].*$/,''

gsub_file 'Gemfile', /^gem\s+["']jquery-rails["'].*$/,''
gem 'jquery-rails', git: 'git://github.com/rails/jquery-rails.git'

gem 'oj'
gem 'slowpoke'
gem 'rack-attack'
gem 'dalli'
gem 'active_model_serializers'
gem 'hamlit'
gem 'autoprefixer-rails'
gem 'lograge'
gem 'contracts'
gem 'wisper'

rails_assets = <<-eos

source 'https://rails-assets.org' do
  gem 'rails-assets-normalize.css'
  gem 'rails-assets-lodash'
  gem 'rails-assets-react'
  gem 'rails-assets-velocity'
  gem 'rails-assets-pubsub-js'
  gem 'rails-assets-rsvp'
  gem 'rails-assets-immutable'
end
eos

append_file 'Gemfile', rails_assets

gem_group :development do
  gem 'heroku'
  gem 'better_errors'
  gem 'guard'
  gem 'rb-fsevent'
  gem 'guard-livereload', require: false
  gem 'rack-livereload'
  gem 'rack-mini-profiler'
  gem 'flamegraph'
  gem 'stackprof'
  gem 'memory_profiler'
end

gem_group :test do
  gem 'capybara'
  gem 'poltergeist'
  gem 'webmock'
  gem 'factory_girl_rails'
  gem 'database_cleaner'
end

gem_group :development, :test do
  gem 'rspec-rails'
  gem 'awesome_print'
  gem 'faker'
  gem 'pry-rails'
  gem 'binding_of_caller'
  gem 'dotenv-rails'
end

gem_group :production, :staging do
  gem 'rails_12factor'
end

# -----------------------------
# LOGRAGE
# -----------------------------
initializer 'lograge.rb', render_file("#{$path}/files/lograge.rb", class_app_name: $class_app_name)

# -----------------------------
# AUTOPREFIXER
# -----------------------------
file 'config/autoprefixer.yml', IO.read("#{$path}/files/autoprefixer.yml")

# -----------------------------
# LIVERELOAD
# -----------------------------
environment 'config.middleware.insert_before Rack::Runtime, Rack::LiveReload', env: 'development'

# -----------------------------
# DATABASE
# -----------------------------
run 'rm config/database.yml'
file 'config/database.yml', render_file("#{$path}/files/database.yml", app_name: app_name)

environment 'config.active_record.primary_key = :uuid'
file "db/migrate/#{DateTime.now.strftime("%Y%m%d%H%M%S")}_enable_uuid.rb", IO.read("#{$path}/files/enable_uuid.rb")

environment 'config.active_record.schema_format = :sql'

# -----------------------------
# SYSTEM SETUP
# -----------------------------
packages = []
packages << 'phantomjs'

system 'brew tap homebrew/bundle'
file 'Brewfile', render_file("#{$path}/files/Brewfile", packages: packages)
file 'bin/deploy', IO.read("#{$path}/files/deploy")
file 'lib/tasks/dev.rake', IO.read("#{$path}/files/dev.rake")
run 'chmod +x bin/deploy'

# -----------------------------
# VIEWS
# -----------------------------
run 'rm app/views/layouts/application.html.erb'
file 'app/views/layouts/application.html.haml',
     render_file("#{$path}/files/application.html.haml", human_app_name: $human_app_name, class_app_name: $class_app_name)

# -----------------------------
# ASSETS
# -----------------------------
css_manifest = <<eos
 *= require normalize.css/normalize
 *= require application/all
eos

asset_initializer = <<~eos
  #{render_file("#{$path}/files/auto_assets.rb", class_app_name: $class_app_name)}

  Rails.application.config.assets.precompile += #{$class_app_name}::AutoAssets.all
eos

prepend_file 'config/initializers/assets.rb', asset_initializer

run 'mkdir app/assets/stylesheets/application'
file 'app/assets/stylesheets/application/all.sass', IO.read("#{$path}/files/all.sass")
gsub_file "app/assets/stylesheets/application.css",
          /^.*require_tree \.$/,
          css_manifest

run 'mkdir app/assets/javascripts/application'
file 'app/assets/javascripts/application/entry.coffee', render_file("#{$path}/files/entry.coffee", class_app_name: $class_app_name)
run 'rm app/assets/javascripts/application.js'
file 'app/assets/javascripts/application.js', IO.read("#{$path}/files/application.js")

# -----------------------------
# JS-RAILS INTERCHANGE
# -----------------------------
file 'app/controllers/concerns/interchange.rb', IO.read("#{$path}/files/interchange.rb")
file 'lib/assets/javascripts/interchange.coffee', IO.read("#{$path}/files/interchange.coffee")
insert_into_file 'app/controllers/application_controller.rb', "  include Interchange\n",
                 after: "class ApplicationController < ActionController::Base\n"
insert_into_file 'app/assets/javascripts/application.js', "\n//= require interchange\n",
                 before: "\n//= require_tree ./application"

# -----------------------------
# RACK ATTACK
# -----------------------------
initializer 'rack-attack.rb', IO.read("#{$path}/files/rack-attack.rb")
environment 'config.middleware.use Rack::Attack'

# -----------------------------
# PUMA
# -----------------------------
file 'Procfile', IO.read("#{$path}/files/Procfile")

system 'rm config/puma.rb'
file 'config/puma.rb', IO.read("#{$path}/files/puma.rb")

# -----------------------------
# HEROKU
# -----------------------------
file 'bin/heroku-config', render_file("#{$path}/files/heroku-config", app_name: app_name)
system 'chmod +x bin/heroku-config'

# -----------------------------
# GUARD
# -----------------------------
file 'Guardfile', IO.read("#{$path}/files/Guardfile")

# -----------------------------
# DOTENV
# -----------------------------
file '.env', IO.read("#{$path}/files/env")

# -----------------------------
# MAKE READY
# -----------------------------
after_bundle do
  run "dropdb #{app_name}"
  run "dropdb #{app_name}_test"
  run "dropuser #{app_name}"
  run "createuser -s #{app_name}"
  run "createdb #{app_name}"
  run "createdb #{app_name}_test"

  rake 'db:migrate'

  run 'rm bin/setup'
  file 'bin/setup', render_file("#{$path}/files/setup", app_name: app_name)
  run 'chmod +x bin/setup'

  run 'brew bundle'

  generate 'rspec:install'

  generate 'slowpoke:install'

# -----------------------------
# SPEC FILES ADDITIONS
# -----------------------------
  rails_helper_requires = <<~eos

    require 'webmock/rspec'
    require 'active_support/testing/time_helpers'

    # load all files in spec/support
    Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }
  eos

  rails_helper_additions = <<eos
  config.include ActiveSupport::Testing::TimeHelpers
eos

  gsub_file 'spec/rails_helper.rb', /^\W+config\.fixture_path.*\n$/, ''

  insert_into_file 'spec/rails_helper.rb', rails_helper_requires,
                   after: "require 'rspec/rails'\n"

  insert_into_file 'spec/rails_helper.rb', rails_helper_additions,
                   after: "RSpec.configure do |config|\n"

  file 'spec/support/database_cleaner.rb', IO.read("#{$path}/files/database_cleaner.rb")
  file 'spec/support/factory_girl.rb', IO.read("#{$path}/files/factory_girl.rb")

  file 'spec/support/capybara.rb', IO.read("#{$path}/files/capybara.rb")

  # -----------------------------
  # GIT
  # -----------------------------
  git :init
  run "git remote add production git@heroku.com:#{app_name}.git"
  run "git remote add staging git@heroku.com:#{app_name}-staging.git"
  git add: %Q{--all}
  git commit: %Q{-m 'initial commit'}

  puts '------------------------------------------'
  puts '------------------------------------------'
  puts 'all done!'
  puts 'you should really go clean up / organize the gemfile, spec_helper, & rails_helper now'
  puts '------------------------------------------'
  puts '------------------------------------------'
end
