require 'erb'
require 'ostruct'

$ruby_version = '2.1.2'
$path = File.expand_path(File.dirname(__FILE__))

# -----------------------------
# NOTES
# -----------------------------
# /usr/local/bin should be in your path (for both homebrew and npm stuff)
# Postgres (use postgres.app from https://github.com/PostgresApp/PostgresApp/releases)
# Hombrew

# -----------------------------
# QUESTIONS
# -----------------------------
$api_only = yes?('is this an api only application?')

# -----------------------------
# HELPER FUCTIONS
# -----------------------------
def render_file(path, variables)
  file = File.open(path).read
  struct = OpenStruct.new(variables)
  rendered_file = ERB.new(file).result(struct.instance_eval { binding })
end

# -----------------------------
# WATCHABLE LIB
# -----------------------------
# use require_dependecy to require
insert_into_file 'config/application.rb', "\n    config.watchable_dirs['lib'] = [:rb]",
                 after: "  class Application < Rails::Application"

# -----------------------------
# DOCUMENTATION
# -----------------------------
run 'rm README.rdoc'
file 'readme.md', render_file("#{$path}/files/readme.md", app_title: app_name.humanize)

# -----------------------------
# GEMFILE
# -----------------------------
# specify ruby version
insert_into_file 'Gemfile', "\nruby '#{$ruby_version}'",
                 after: "source 'https://rubygems.org'\n"

insert_into_file 'Gemfile', "source 'https://rails-assets.org'",
                 after: "source 'https://rubygems.org'\n"

# remove gems
gsub_file 'Gemfile', /^gem\s+["']sqlite3["'].*$/,''
gsub_file 'Gemfile', /^gem\s+["']turbolinks["'].*$/,''
gsub_file 'Gemfile', /^\s+gem\s+["']sdoc["'].*$/,''
gsub_file 'Gemfile', /^gem\s+["']sass-rails["'].*$/,'' if $api_only
gsub_file 'Gemfile', /^gem\s+["']uglifier["'].*$/,'' if $api_only
gsub_file 'Gemfile', /^gem\s+["']coffee-rails["'].*$/,'' if $api_only
gsub_file 'Gemfile', /^gem\s+["']jquery-rails["'].*$/,'' if $api_only

gsub_file 'app/assets/javascripts/application.js', /^.*require turbolinks.*$/,'' if !$api_only

# add gems
gem 'rack-mini-profiler' if !$api_only
gem 'pg'
gem 'passenger'
gem 'oj'
gem 'slim-rails' if !$api_only
gem 'compass-rails' if !$api_only

gem 'rails-assets-normalize.css' if !$api_only

gem_group :development do
  gem "brewdler"
  gem "heroku"
  gem "better_errors"
  gem "binding_of_caller"
  gem "coffee-rails-source-maps" if !$api_only
  gem 'guard' if !$api_only
  gem 'rb-fsevent' if !$api_only
  gem 'guard-livereload', require: false if !$api_only
  gem "rack-livereload" if !$api_only
end

gem_group :test do
  gem "spring-commands-rspec"
  gem "rspec-rails"
  gem "webmock"
  gem "factory_girl_rails"
  gem "database_cleaner"
end

gem_group :development, :test do
  gem "awesome_print"
  gem "pry-rails"
  gem "dotenv-rails"
end

gem_group :production, :staging do
  gem 'rails_12factor'
  gem 'rails_stdout_logging'
  gem 'rails_serve_static_assets'
end

# -----------------------------
# LIVERELOAD
# -----------------------------
if !$api_only
  insert_into_file 'config/environments/development.rb', "  config.middleware.insert_before Rack::Lock, Rack::LiveReload\n",
                    after: "Rails.application.configure do\n"
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

optional_packages = []
file 'Brewfile', render_file("#{$path}/files/Brewfile", optional_packages: optional_packages)
file 'bin/deploy', File.open("#{$path}/files/deploy").read
file 'lib/tasks/dev.rake', File.open("#{$path}/files/dev.rake").read
run "chmod +x bin/deploy"

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
 *= requre all
eos

  run 'mkdir app/assets/stylesheets/application'
  run 'touch app/assets/stylesheets/application/all.sass'
  gsub_file "app/assets/stylesheets/application.css",
            /^.*require_tree \.$/,
            css_manifest

  run 'mkdir app/assets/javascripts/application'
  run 'touch app/assets/javascripts/application/app.coffee'
  gsub_file 'app/assets/javascripts/application.js',
            /^\/\/= require_tree \.$/,
            '//= require application/app'

  run 'touch app/assets/stylesheets/debug.css'
  prepend_file 'app/assets/stylesheets/debug.css',
               '/* = require pesticide */'

  prepend_file 'config/initializers/assets.rb',
               'Rails.application.config.assets.precompile += %w( debug.css )'

  file 'vendor/assets/stylesheets/pesticide.scss', File.open("#{$path}/files/pesticide.scss").read
end

# -----------------------------
# PASSENGER
# -----------------------------
file 'Procfile', File.open("#{$path}/files/Procfile").read

# -----------------------------
# Guard
# -----------------------------
if !$api_only
  file 'Guardfile', File.open("#{$path}/files/Guardfile").read
end

# -----------------------------
# RSPEC
# -----------------------------
run 'rm -rf test'

# -----------------------------
# DOTENV
# -----------------------------
run 'touch .env'

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

rake "db:migrate"
generate 'rspec:install'
run 'bundle exec spring binstub --all'

# -----------------------------
# SPEC FILES ADDITIONS
# -----------------------------
spec_helper_additions = <<eos
  config.include FactoryGirl::Syntax::Methods

  config.before(:all) do
    DatabaseCleaner.strategy = :deletion
    DatabaseCleaner.start
  end

  config.after(:all) do
    DatabaseCleaner.clean
  end
eos

insert_into_file 'spec/spec_helper.rb', spec_helper_additions,
                 after: "RSpec.configure do |config|\n"

prepend_file 'spec/spec_helper.rb', "require 'webmock/rspec'\n"
prepend_file 'spec/spec_helper.rb', "require 'factory_girl_rails'\n"

# -----------------------------
# GIT
# -----------------------------
git :init
run "git remote add production git@heroku.com:#{app_name}.git"
run "git remote add staging git@heroku.com:#{app_name}-staging.git"
append_file '.gitignore', "\n/public/assets/source_maps"
git add: '.'
git commit: %Q{ -m 'initial commit' }
