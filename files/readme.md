# <%= app_title %>

## Dependencies
- Hombrew
- Postgres (use postgres.app from https://github.com/PostgresApp/PostgresApp/releases)

## System Setup
- Run bin/setup

## Development
- Run rake dev:init to wipe everything and start fresh

## Deployment
- run bin/deploy app-name branch-name
- heroku config variables are stored / can be added in bin/heroku-config
    - running this file will update / add new variables
    - to remove a variable remove it from the file and then run heroku
      config:unset VARIABLE
