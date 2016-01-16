require 'erb'
require 'ostruct'

$ruby_version = '2.3.0'
$path = File.expand_path(File.dirname(__FILE__))

$human_app_name = app_name.humanize
$class_app_name = app_name.gsub('-', '_').camelize

# -----------------------------
# QUESTIONS
# -----------------------------
$api_only = yes?('is this an api only application?')

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
run 'rm README.rdoc'
file 'readme.md', render_file("#{$path}/files/readme.md", human_app_name: $human_app_name)

# -----------------------------
# GEMFILE
# -----------------------------
insert_into_file 'Gemfile', "\nruby '#{$ruby_version}'",
                 after: "source 'https://rubygems.org'\n"

gsub_file 'Gemfile', /^gem\s+["']sqlite3["'].*$/,''
gsub_file 'Gemfile', /^gem\s+["']turbolinks["'].*$/,''
gsub_file 'Gemfile', /^gem\s+["']sdoc["'].*$/,''
gsub_file 'Gemfile', /^gem\s+["']sass-rails["'].*$/,'' if $api_only
gsub_file 'Gemfile', /^gem\s+["']uglifier["'].*$/,'' if $api_only
gsub_file 'Gemfile', /^gem\s+["']coffee-rails["'].*$/,'' if $api_only
gsub_file 'Gemfile', /^gem\s+["']jquery-rails["'].*$/,'' if $api_only

gsub_file 'app/assets/javascripts/application.js', /^.*require turbolinks.*$/,'' if !$api_only

gem 'pg'
gem 'puma'
gem 'oj'
gem 'slowpoke'
gem 'rack-attack'
gem 'active_model_serializers'
gem 'haml' if !$api_only
gem 'autoprefixer-rails' if !$api_only
gem 'lograge'

rails_assets = <<-eos

source 'https://rails-assets.org' do
  gem 'rails-assets-normalize.css'
  gem 'rails-assets-lodash'
end
eos

append_file 'Gemfile', rails_assets if !$api_only

gem_group :development do
  gem 'heroku'
  gem 'better_errors'
  gem 'quiet_assets' if !$api_only
  gem 'guard' if !$api_only
  gem 'rb-fsevent' if !$api_only
  gem 'guard-livereload', require: false if !$api_only
  gem 'rack-livereload' if !$api_only
  gem 'rack-mini-profiler' if !$api_only
  gem 'flamegraph' if !$api_only
  gem 'stackprof' if !$api_only
  gem 'memory_profiler' if !$api_only
end

gem_group :test do
  gem 'capybara' if !$api_only
  gem 'poltergeist' if !$api_only
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
# APPLICATION.RB
# -----------------------------
# Pick pieces from https://github.com/rails/rails/blob/master/railties/lib/rails/all.rb
gsub_file 'config/application.rb', /^.*require 'rails\/all'$/,
          parts = <<eos
require 'active_record/railtie'
require 'action_controller/railtie'
require 'action_view/railtie'
require 'rails/test_unit/railtie'
require 'sprockets/railtie'
eos

gsub_file 'config/environments/development.rb', /^.*config\.action_mailer\.raise_delivery_errors = false$/,
          '  # config.action_mailer.raise_delivery_errors = false'

gsub_file 'config/environments/test.rb', /^.*config\.action_mailer\.delivery_method = :test$/,
          '  # config.action_mailer.delivery_method = :test'

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
if !$api_only
  environment 'config.middleware.insert_before Rack::Lock, Rack::LiveReload', env: 'development'
end

# -----------------------------
# DATABASE
# -----------------------------
run 'rm config/database.yml'
file 'config/database.yml', render_file("#{$path}/files/database.yml", app_name: app_name)

# -----------------------------
# SYSTEM SETUP
# -----------------------------
packages = []
packages << 'phantomjs' if !$api_only

system 'brew tap homebrew/bundle'
file 'Brewfile', render_file("#{$path}/files/Brewfile", packages: packages)
file 'bin/deploy', IO.read("#{$path}/files/deploy")
file 'lib/tasks/dev.rake', IO.read("#{$path}/files/dev.rake")
run 'chmod +x bin/deploy'

# -----------------------------
# APIS
# -----------------------------
if $api_only
  gsub_file 'app/controllers/application_controller.rb', /^.*protect_from_forgery with: :exception$/,
            '  protect_from_forgery with: :null_session'
end

# -----------------------------
# VIEWS
# -----------------------------
if $api_only
  run 'rm app/views/layouts/application.html.erb'
else
  run 'rm app/views/layouts/application.html.erb'
  file 'app/views/layouts/application.html.haml',
       render_file("#{$path}/files/application.html.haml", human_app_name: $human_app_name, class_app_name: $class_app_name)
end

# -----------------------------
# ASSETS
# -----------------------------
if $api_only
  run 'rm -rf app/assets'
  run 'rm -rf vendor/assets'
else
  css_manifest = <<eos
 *= require normalize.css/normalize
 *= require application/all
eos

  asset_initializer = <<eos
#{render_file("#{$path}/files/auto_assets.rb", class_app_name: $class_app_name)}

Rails.application.config.assets.precompile += #{$class_app_name}::AutoAssets.all
eos

  run 'mkdir app/assets/stylesheets/application'
  file 'app/assets/stylesheets/application/all.sass', IO.read("#{$path}/files/all.sass")
  gsub_file "app/assets/stylesheets/application.css",
            /^.*require_tree \.$/,
            css_manifest

  run 'mkdir app/assets/javascripts/application'
  file 'app/assets/javascripts/application/entry.coffee', render_file("#{$path}/files/entry.coffee", class_app_name: $class_app_name)
  gsub_file 'app/assets/javascripts/application.js',
            /^\/\/= require_tree \.$/,
            '//= require_tree ./application'

  prepend_file 'config/initializers/assets.rb',
               asset_initializer

  insert_into_file 'app/assets/javascripts/application.js', '//= require lodash/lodash',
                   after: "//= require jquery_ujs\n"

  gsub_file 'app/assets/javascripts/application.js',
            /^\/\/= require jquery\n/,
            "//= require jquery2\n"
end

# -----------------------------
# JS-RAILS INTERCHANGE
# -----------------------------
if !$api_only
  file 'app/controllers/concerns/interchange.rb', IO.read("#{$path}/files/interchange.rb")
  file 'lib/assets/javascripts/interchange.coffee', IO.read("#{$path}/files/interchange.coffee")
  insert_into_file 'app/controllers/application_controller.rb', "  include Interchange\n",
                   after: "class ApplicationController < ActionController::Base\n"
  insert_into_file 'app/assets/javascripts/application.js', "\n//= require interchange\n",
                   before: "\n//= require_tree ./application"
end

# -----------------------------
# RACK ATTACK
# -----------------------------
initializer 'rack-attack.rb', IO.read("#{$path}/files/rack-attack.rb")
environment 'config.middleware.use Rack::Attack'

# -----------------------------
# PUMA
# -----------------------------
file 'Procfile', IO.read("#{$path}/files/Procfile")
file 'config/puma.rb', IO.read("#{$path}/files/puma.rb")

# -----------------------------
# HEROKU
# -----------------------------
file 'bin/heroku-config', render_file("#{$path}/files/heroku-config", app_name: app_name)
system 'chmod +x bin/heroku-config'

# -----------------------------
# GUARD
# -----------------------------
if !$api_only
  file 'Guardfile', IO.read("#{$path}/files/Guardfile")
end

# -----------------------------
# RSPEC
# -----------------------------
run 'rm -rf test'

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
  # remove spring, regenerate binstubs
  run 'rm -rf ./bin/'
  gsub_file 'Gemfile', /^\s+gem\s+["']spring["'].*$/,''
  run 'bundle install'
  rake 'rails:update:bin'

  run 'rm bin/setup'
  file 'bin/setup', render_file("#{$path}/files/setup", app_name: app_name)
  run 'chmod +x bin/setup'

  run 'brew bundle'

  generate 'rspec:install'
  run 'bundle binstubs rspec-core'

  generate 'slowpoke:install' if !$api_only

# -----------------------------
# SPEC FILES ADDITIONS
# -----------------------------
  rails_helper_requires = <<eos

require 'factory_girl_rails'
require 'webmock/rspec'
require 'active_support/testing/time_helpers'
eos

  rails_helper_requires << <<eos if !$api_only
require 'capybara'
require 'capybara/poltergeist'
eos

  rails_helper_additions = <<eos
  config.include ActiveSupport::Testing::TimeHelpers

  config.include FactoryGirl::Syntax::Methods

  config.before(:all) do
    DatabaseCleaner.strategy = :deletion
    DatabaseCleaner.start
    FactoryGirl.lint
  end

  config.after(:all) do
    DatabaseCleaner.clean
  end
eos

  rails_helper_additions << <<eos if !$api_only

  config.before(:each, js: true) do
    page.driver.browser.url_blacklist = []
  end
eos

  environment 'config.allow_concurrency = false', env: 'test'

  gsub_file 'spec/rails_helper.rb', /^\W+config\.fixture_path.*\n$/, ''

  insert_into_file 'spec/rails_helper.rb', rails_helper_requires,
                   after: "require 'rspec/rails'\n" if !$api_only

  insert_into_file 'spec/rails_helper.rb', rails_helper_additions,
                   after: "RSpec.configure do |config|\n"

  insert_into_file 'spec/rails_helper.rb', "  Capybara.javascript_driver = :poltergeist\n",
                   after: "RSpec.configure do |config|\n" if !$api_only


  # -----------------------------
  # GIT
  # -----------------------------
  git :init
  run "git remote add production git@heroku.com:#{app_name}.git"
  run "git remote add staging git@heroku.com:#{app_name}-staging.git"
  append_file '.gitignore', "\n/public/assets/source_maps"
  git add: %Q{ --all }
  git commit: %Q{ -m 'initial commit' }
end
