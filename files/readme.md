# <%= human_app_name %>

## Style Guides
- https://github.com/bbatsov/rails-style-guide
- http://www.betterspecs.org

## Dependencies
- Hombrew
- Postgres (use postgres.app from https://github.com/PostgresApp/PostgresApp/releases)

## System Setup
- Run bin/setup

## Development
- Run rake dev:init to wipe everything and start fresh
- Make sure that all tests pass and there are no rubocop warnings before
  committing by running `be rubocop && be rspec`

## Deployment
- run bin/deploy app-name branch-name
- heroku config variables are stored / can be added in bin/heroku-config
    - running this file will update / add new variables
    - to remove a variable remove it from the file and then run heroku
      config:unset VARIABLE

## Javascripts
### Manifests
Javascript manifests for controllers and actions are included
automatically if you name them correctly.

~~~~
controller: static_controller.rb
action: home
controller manifest name: static.js
action manifest name: static-home.js

controller: admin/static_controller.rb
action: home
controller manifest name: admin~static.js
action manifest name: admin~static-home.js
~~~~

### Interchange
Set variables in a controller with...

~~~~
interchange(key: 'value')
~~~~

Access values in javascript with...

~~~~
Interchange.key
~~~~
