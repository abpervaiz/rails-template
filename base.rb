require 'erb'
require 'ostruct'

$ruby_version = '2.1.1'
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
# user require_dependecy to require
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
gem 'pg'
gem 'passenger'
gem 'heroku'
gem 'oj'
gem 'slim-rails' if !$api_only
gem 'simple_form' if !$api_only
gem 'bower-rails' if !$api_only
gem 'compass-rails' if !$api_only

gem_group :development do
  gem 'pry-rails'
  gem 'binding_of_caller'
  gem 'better_errors'
  gem 'coffee-rails-source-maps' if !$api_only
end

gem_group :development, :test do
  gem 'rspec-rails'
  gem 'webmock'
  gem 'factory_girl_rails'
  gem "database_cleaner", git: 'https://github.com/bmabey/database_cleaner.git'
  gem 'dotenv-rails'
end

gem_group :production, :staging do
  gem 'rails_12factor'
  gem 'rails_stdout_logging'
  gem 'rails_serve_static_assets'
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
optional_packages << "node" if !$api_only
file 'Brewfile', render_file("#{$path}/files/Brewfile", optional_packages: optional_packages)
file 'bin/deploy', File.open("#{$path}/files/deploy").read
run "chmod +x bin/deploy"

# -----------------------------
# APIS
# -----------------------------
gsub_file 'app/controllers/application_controller.rb', /^.*protect_from_forgery with: :exception$/,
          '  protect_from_forgery with: :null_session'

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
  run 'touch app/assets/stylesheets/all.sass'
  gsub_file "app/assets/stylesheets/application.css",
            /^.*require_tree \.$/,
            ' *= require all'

  run 'touch app/assets/javascripts/app.coffee'
  gsub_file 'app/assets/javascripts/application.js',
            /^\/\/= require_tree \.$/,
            '//= require app'
end

# -----------------------------
# PASSENGER
# -----------------------------
file 'Procfile', File.open("#{$path}/files/Procfile").read

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
git :init
run 'bundle install'
run './bin/setup'
rake 'db:migrate'
generate 'rspec:install'

if !$api_only
  generate 'bower_rails:initialize'
  generate 'simple_form:install'
  run 'npm install bower'
end

# -----------------------------
# BOWER
# -----------------------------
if !$api_only
  run 'rm Bowerfile'
  file 'Bowerfile', File.open("#{$path}/files/Bowerfile").read

  insert_into_file 'app/assets/javascripts/application.js',
                   "\n//= require rubyjs/ruby\n",
                   after: "//= require jquery_ujs\n"

  append_file 'app/assets/stylesheets/all.sass' do File.open("#{$path}/files/all.sass").read end
  gsub_file 'config/initializers/bower_rails.rb', /^  # bower_rails.resolve_before_precompile = true$/,
            '  bower_rails.resolve_before_precompile = true'

  rake 'bower:install'
end

# -----------------------------
# SPEC FILES ADDITIONS
# -----------------------------
spec_helper_additions = <<eos
  config.include FactoryGirl::Syntax::Methods

  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end
eos

insert_into_file 'spec/spec_helper.rb', spec_helper_additions,
                 after: "RSpec.configure do |config|\n"

insert_into_file 'spec/spec_helper.rb', "require 'webmock/rspec'\n",
                 after: "require 'rspec/autorun'\n"

# -----------------------------
# GIT
# -----------------------------
append_file '.gitignore', "\n/public/assets/source_maps"
git add: '.'
git commit: %Q{ -m 'initial commit' }
