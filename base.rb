require 'erb'
require 'ostruct'

$ruby_version = '2.2.0'
$path = File.expand_path(File.dirname(__FILE__))

# -----------------------------
# QUESTIONS
# -----------------------------
$api_only = yes?('is this an api only application?')

# -----------------------------
# HELPER FUCTIONS
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
file 'readme.md', render_file("#{$path}/files/readme.md", app_title: app_name.humanize)

# -----------------------------
# GEMFILE
# -----------------------------
insert_into_file 'Gemfile', "\nruby '#{$ruby_version}'",
                 after: "source 'https://rubygems.org'\n"

add_source 'https://rails-assets.org'

gsub_file 'Gemfile', /^gem\s+["']sqlite3["'].*$/,''
gsub_file 'Gemfile', /^gem\s+["']turbolinks["'].*$/,''
gsub_file 'Gemfile', /^\s+gem\s+["']sdoc["'].*$/,''
gsub_file 'Gemfile', /^gem\s+["']sass-rails["'].*$/,'' if $api_only
gsub_file 'Gemfile', /^gem\s+["']uglifier["'].*$/,'' if $api_only
gsub_file 'Gemfile', /^gem\s+["']coffee-rails["'].*$/,'' if $api_only
gsub_file 'Gemfile', /^gem\s+["']jquery-rails["'].*$/,'' if $api_only

gsub_file 'app/assets/javascripts/application.js', /^.*require turbolinks.*$/,'' if !$api_only

gem 'pg'
gem 'passenger'
gem 'oj'
gem 'slowpoke'
gem 'rack-attack'
gem 'slim-rails' if !$api_only
gem 'compass-rails' if !$api_only

gem 'rails-assets-normalize.css' if !$api_only
gem 'rails-assets-lodash' if !$api_only

gem_group :development do
  gem 'brewdler'
  gem 'heroku'
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'coffee-rails-source-maps' if !$api_only
  gem 'quiet_assets' if !$api_only
  gem 'guard' if !$api_only
  gem 'rb-fsevent' if !$api_only
  gem 'guard-livereload', require: false if !$api_only
  gem 'rack-livereload' if !$api_only
end

gem_group :test do
  gem 'capybara' if !$api_only
  gem 'poltergeist' if !$api_only
  gem 'spring-commands-rspec'
  gem 'rspec-rails'
  gem 'webmock'
  gem 'factory_girl_rails'
  gem 'database_cleaner'
end

gem_group :development, :test do
  gem 'awesome_print'
  gem 'faker'
  gem 'pry-rails'
  gem 'dotenv-rails'
end

gem_group :production, :staging do
  gem 'rails_12factor'
  gem 'rails_stdout_logging'
  gem 'rails_serve_static_assets'
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
file 'bin/setup', render_file("#{$path}/files/setup", app_name: app_name)
run 'chmod +x bin/setup'

packages = []
packages << 'phantomjs' if !$api_only

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
# HELPER
# -----------------------------
if !$api_only
  run 'rm app/helpers/application_helper.rb'
  file 'app/helpers/application_helper.rb', IO.read("#{$path}/files/application_helper.rb")
end

# -----------------------------
# VIEWS
# -----------------------------
if $api_only
  run 'rm app/views/layouts/application.html.erb'
else
  run 'rm app/views/layouts/application.html.erb'
  file 'app/views/layouts/application.html.slim',
       render_file("#{$path}/files/application.html.slim", app_title: app_name.humanize)
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

  asset_initializer = <<-'eos'
all_js = Dir.glob("#{Rails.root}/app/assets/javascripts/*").select { |f| !File.directory?(f) }.map { |f| File.basename(f)[/((\w|-)*)/] + ".js" }
all_css = Dir.glob("#{Rails.root}/app/assets/stylesheets/*").select { |f| !File.directory?(f) }.map { |f| File.basename(f)[/((\w|-)*)/] + ".css" }
assets = (all_js + all_css).select { |f| !f.include?('application') }

Rails.application.config.assets.precompile += assets
eos

  run 'mkdir app/assets/stylesheets/application'
  run 'touch app/assets/stylesheets/application/all.sass'
  gsub_file "app/assets/stylesheets/application.css",
            /^.*require_tree \.$/,
            css_manifest

  run 'mkdir app/assets/javascripts/application'
  file 'app/assets/javascripts/application/app.coffee', render_file("#{$path}/files/app.coffee", app_name: app_name.gsub('-', '_').camelize)
  gsub_file 'app/assets/javascripts/application.js',
            /^\/\/= require_tree \.$/,
            '//= require application/app'

  run 'touch app/assets/stylesheets/debug.css'
  prepend_file 'app/assets/stylesheets/debug.css',
               '/* = require pesticide */'

  prepend_file 'config/initializers/assets.rb',
               asset_initializer

  insert_into_file 'app/assets/javascripts/application.js', '//= require lodash/lodash',
                   after: "//= require jquery_ujs\n"

  gsub_file 'app/assets/javascripts/application.js',
            /^\/\/= require jquery\n/,
            "//= require jquery2\n"

  file 'vendor/assets/stylesheets/pesticide.scss', IO.read("#{$path}/files/pesticide.scss")
end

# -----------------------------
# RACK ATTACK
# -----------------------------
initializer 'rack-attack.rb', IO.read("#{$path}/files/rack-attack.rb")
environment 'config.middleware.use Rack::Attack'

# -----------------------------
# PASSENGER
# -----------------------------
file 'Procfile', IO.read("#{$path}/files/Procfile")

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
run "dropdb #{app_name}"
run "dropdb #{app_name}_test"
run "dropuser #{app_name}"
run "createuser -s #{app_name}"
run "createdb #{app_name}"
run "createdb #{app_name}_test"

run 'bundle install'
run 'brewdle install'

rake 'db:migrate'
generate 'rspec:install'
generate 'slowpoke:install' if !$api_only

run 'bundle exec spring binstub --all'

# -----------------------------
# SPEC FILES ADDITIONS
# -----------------------------
spec_helper_additions = <<eos
  config.include ActiveSupport::Testing::TimeHelpers

  config.include FactoryGirl::Syntax::Methods

  config.before(:all) do
    DatabaseCleaner.strategy = :deletion
    DatabaseCleaner.start
  end

  config.after(:all) do
    DatabaseCleaner.clean
  end
eos

spec_helper_additions << <<eos if !$api_only

  config.before(:each, js: true) do
    page.driver.browser.url_blacklist = ["http://use.typekit.net"]
  end
eos

environment 'config.allow_concurrency = false', env: 'test'

insert_into_file 'spec/spec_helper.rb', spec_helper_additions,
                 after: "RSpec.configure do |config|\n"

insert_into_file 'spec/spec_helper.rb', "  Capybara.javascript_driver = :poltergeist\n",
                 after: "RSpec.configure do |config|\n" if !$api_only

prepend_file 'spec/spec_helper.rb', "require 'active_support/testing/time_helpers'\n"
prepend_file 'spec/spec_helper.rb', "require 'webmock/rspec'\n"
prepend_file 'spec/spec_helper.rb', "require 'factory_girl_rails'\n"
prepend_file 'spec/spec_helper.rb', "require 'capybara/poltergeist'\n" if !$api_only
prepend_file 'spec/spec_helper.rb', "require 'capybara'\n" if !$api_only

# -----------------------------
# GIT
# -----------------------------
git :init
run "git remote add production git@heroku.com:#{app_name}.git"
run "git remote add staging git@heroku.com:#{app_name}-staging.git"
append_file '.gitignore', "\n/public/assets/source_maps"
git add: '.'
git commit: %Q{ -m 'initial commit' }
