require 'capybara'
require 'capybara/poltergeist'

RSpec.configure do |config|
  Capybara.javascript_driver = :poltergeist

  config.before(:each, js: true) do
    page.driver.browser.url_blacklist = []
  end
end
