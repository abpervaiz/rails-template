namespace :dev do
  desc 'clean dev & test environment'
  task reset: ['db:drop', 'db:create', 'db:structure:load', 'tmp:clear', 'db:seed'] do
  end
end
