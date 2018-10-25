# Insights Compliance Backend

compliance-backend is a project meant to parse OpenSCAP reports into a database,
and perform all kind of actions that will make your systems more compliant with
a policy. For example, you should be able to generate reports of all kinds for
your auditors, get alerts, and create playbooks to fix your hosts.


## Getting started

This project does two main things:

1 - Connect to a Kafka message queue [provided by the Insights Platform](https://github.com/RedHatInsights/insights-upload)
2 - Serve as the backend API for the web UI [compliance-frontend](https://github.com/RedHatInsights/compliance-frontend)

Let's examine how to run the project:

### Option 1: [OpenShift](https://www.openshift.com/)

You may use the templates in `openshift/templates/` and upload them to
Openshift to run the project without any further configuration.


### Option 2: Development setup

compliance-backend is a Ruby on Rails application. It should run using
at least two different processes:

#### Shared prerequisites

Prerequisites:

* URL to Kafka
  - environment variable: `KAFKAMQ`
* URL to PostgreSQL database
  - environment variables: `POSTGRESQL_DATABASE`, `POSTGRESQL_SERVICE_HOST`, `POSTGRESQL_USER`, `POSTGRESQL_PASSWORD`, `POSTGRESQL_ADMIN_PASSWORD`, `DATABASE_SERVICE_NAME`

First, let's install all dependencies and initialize the database.

```shell
bundle install
bundle exec rake db:create db:migrate
```

#### Kafka consumers

At this point you can launch as many ['racecar'](https://github.com/zendesk/racecar)
processes as you want. These processes will become part of a *consumer group*
in Kafka, so by default the system is highly available.

To run a Reports consumer:

```shell
bundle exec racecar ComplianceReportsConsumer
```

#### Web server

You may simply run:

```shell
bundle exec rails server
```

Notice there's no CORS protection by default. If you want your requests to be
CORS-protected, check out `config/initializers/cors.rb` and change it to only
allow a certain domain.

## Contributing

If you'd like to contribute, please fork the repository and use a feature
branch. Pull requests are warmly welcome.

This project ensures code style guidelines are followed on every pull request
using [Rubocop](https://github.com/rubocop-hq/rubocop).

## Licensing

The code in this project is licensed under GPL v3 license.
