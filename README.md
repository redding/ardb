# Ardb

Tools for using ActiveRecord with or without Rails.

## Usage

Given configured database connection parameters, Ardb provides a CLI and assorted tools for working with an ActiveRecord database. Ardb is designed to be used with or without Rails.

### Configuration

By default, Ardb looks for database configuration in the `config/db.rb` file. You can override this using the `ENV["ARDB_DB_FILE"]` env var.

The configuration includes typical database configuration parameters:

```ruby
# in config/db.rb
require "ardb"

Ardb.configure do |c|
  c.logger Logger.new($stdout)
  c.root_path File.expand_path("../..", __FILE__)

  c.db.adapter      "postgresql"
  c.db.encoding     "unicode"
  c.db.min_messages "WARNING"
  c.db.url          "localhost:5432"
  c.db.username     "testuser"
  c.db.password     "secret"
  c.db.database     "testdb"
end
```

#### Rails configuration

If using Ardb with Rails, add a `config/db.rb` file to have Ardb use Rails's configuration settings:

```ruby
# in config/db.rb
require_relative "./environment"
require "ardb"

# This Ardb configuration matches Rails's settings.
Ardb.configure do |c|
  rails_db_config = Rails.application.config_for("database")
  c.root_path     = Rails.root
  c.logger        = Rails.logger
  c.schema_format = Rails.application.config.active_record.schema_format || :ruby
  c.adapter       = rails_db_config["adapter"]
  c.host          = rails_db_config["host"]
  c.port          = rails_db_config["port"]
  c.username      = rails_db_config["username"]
  c.password      = rails_db_config["password"]
  c.database      = rails_db_config["database"]
  c.encoding      = rails_db_config["encoding"]
  c.min_messages  = rails_db_config["min_messages"]

  c.migrations_path = "db/migrate"
  c.schema_path = "db/schema"
end
```

### CLI

```
$ ardb --help
Usage: ardb [COMMAND] [options]

Options:
        --version
        --help

Commands:
  connect            Connect to the configured DB
  create             Create the configured DB
  drop               Drop the configured DB
  generate-migration Generate a MIGRATION-NAME migration file
  migrate            Migrate the configured DB
  migrate-up         Migrate the configured DB up
  migrate-down       Migrate the configured DB down
  migrate-forward    Migrate the configured DB forward
  migrate-backward   Migrate the configured DB backward
```

#### `connect` command

```
$ ardb connect --help
Usage: ardb connect [options]

Options:
        --version
        --help

Description:
  Connect to the configured DB
$ ardb connect
error: database "some_database" does not exist
$ ardb create
created postgresql db "some_database"
$ ardb connect
connected to postgresql db "some_database"
```

Use this command to verify the connection parameter configuration is correct.

#### `create` command

```
$ ardb create --help
Usage: ardb create [options]

Options:
        --version
        --help

Description:
  Create the configured DB
$ ardb create
created postgresql db "some_database"
$ ardb create
error: database "some_database" already exists
```

#### `drop` command

```
$ ardb drop --help
Usage: ardb drop [options]

Options:
        --version
        --help

Description:
  Drop the configured DB
$ ardb drop
dropped postgresql db "some_database"
$ ardb drop
error: database "some_database" does not exist
```

#### `generate-migration` command

```
$ ardb generate-migration add_projects --help
Usage: ardb generate-migration MIGRATION-NAME [options]

Options:
        --version
        --help

Description:
  Generate a MIGRATION-NAME migration file
$ ardb generate-migration add_projects
generated /path/to/app/db/migrate/20191222074043_add_projects.rb
```

#### `migrate` command

```
$ ardb migrate --help
Usage: ardb migrate [options]

Options:
        --version
        --help

Description:
  Migrate the configured DB
$ ardb migrate
== 20191222074043 AddProjects: migrating ======================================
-- create_table(:projects)
   -> 0.0276s
== 20191222074043 AddProjects: migrated (0.0277s) =============================
```

#### `migrate-up` command

```
$ ardb migrate-up --help
Usage: ardb migrate-up [options]

Options:
    -t, --target-version VALUE       version to migrate to
        --version
        --help

Description:
  Migrate the configured DB up
$ ardb migrate-up
== 20191222074043 AddProjects: migrating ======================================
-- create_table(:projects)
   -> 0.0510s
== 20191222074043 AddProjects: migrated (0.0511s) =============================
```

#### `migrate-down` command

```
$ ardb migrate-down --help
Usage: ardb migrate-down [options]

Options:
    -t, --target-version VALUE       version to migrate to
        --version
        --help

Description:
  Migrate the configured DB down
$ ardb migrate-down
== 20191222074043 AddProjects: reverting ======================================
-- drop_table(:projects)
   -> 0.0092s
== 20191222074043 AddProjects: reverted (0.0132s) =============================
```

#### `migrate-forward` command

```
$ ardb migrate-forward --help
Usage: ardb migrate-forward [options]

Options:
    -s, --steps VALUE                number of migrations to migrate
        --version
        --help

Description:
  Migrate the configured DB forward
$ ardb migrate-forward
== 20191222074043 AddProjects: migrating ======================================
-- create_table(:projects)
   -> 0.0510s
== 20191222074043 AddProjects: migrated (0.0511s) =============================
```

#### `migrate-backward` command

```
$ ardb migrate-backward --help
Usage: ardb migrate-backward [options]

Options:
    -s, --steps VALUE                number of migrations to migrate
        --version
        --help

Description:
  Migrate the configured DB backward
$ ardb migrate-backward
== 20191222074043 AddProjects: reverting ======================================
-- drop_table(:projects)
   -> 0.0092s
== 20191222074043 AddProjects: reverted (0.0132s) =============================
```

## Installation

Add this line to your application's Gemfile:

    gem "ardb"

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ardb

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
