namespace :dev do
  desc 'clean dev & test environment'
  task clean: ['db:drop', 'db:create', 'db:structure:load', 'tmp:clear'] do
  end
end
