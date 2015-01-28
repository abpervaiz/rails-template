namespace :dev do
  desc 'reset dev environment'
  task init: ['dev:reset'] do
  end

  task reset: ['dev:clean:test', 'dev:clean:dev'] do
  end

  namespace :clean do
    task dev: ['db:drop', 'db:create', 'db:schema:load']

    task :test do
      rake = "#{Rails.root}/bin/rake"
      system("#{rake} db:drop RAILS_ENV=test")
      system("#{rake} db:create RAILS_ENV=test")
      system("#{rake} db:schema:load RAILS_ENV=test")
    end
  end
end
