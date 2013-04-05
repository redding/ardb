require 'ardb'
require 'ardb/adapter/base'

class Ardb::Adapter

  class Postgresql < Base

    def public_schema_settings
      self.config_settings.merge({
        'database'           => 'postgres',
        'schema_search_path' => 'public'
      })
    end

    def create_db
      ActiveRecord::Base.establish_connection(self.public_schema_settings)
      ActiveRecord::Base.connection.create_database(self.database, self.config_settings)
      ActiveRecord::Base.establish_connection(self.config_settings)
    end

    def drop_db
      ActiveRecord::Base.establish_connection(self.public_schema_settings)
      ActiveRecord::Base.connection.tap do |conn|
        conn.execute "UPDATE pg_catalog.pg_database"\
                     " SET datallowconn=false WHERE datname='#{self.database}'"
        # this SELECT actually runs a command: it terminates all the connections
        # http://www.postgresql.org/docs/9.2/static/functions-admin.html#FUNCTIONS-ADMIN-SIGNAL-TABLE
        conn.execute "SELECT pg_terminate_backend(pid)"\
                     " FROM pg_stat_activity WHERE datname='#{self.database}'"
        conn.execute "DROP DATABASE IF EXISTS #{self.database}"
      end
    end

    def drop_tables
      ActiveRecord::Base.connection.tap do |conn|
        tables = conn.execute "SELECT table_name"\
                              " FROM information_schema.tables"\
                              " WHERE table_schema = 'public';"
        tables.each{ |row| conn.execute "DROP TABLE #{row['table_name']} CASCADE" }
      end
    end

    def foreign_key_add_sql
      "ALTER TABLE :from_table"\
      " ADD CONSTRAINT :name"\
      " FOREIGN KEY (:from_column)"\
      " REFERENCES :to_table (:to_column)"
    end

    def foreign_key_drop_sql
      "ALTER TABLE :from_table"\
      " DROP CONSTRAINT :name"
    end

  end

end
