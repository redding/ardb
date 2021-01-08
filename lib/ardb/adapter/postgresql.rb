# frozen_string_literal: true

require "ardb/adapter/base"

module Ardb::Adapter
  class Postgresql < Ardb::Adapter::Base
    # the "postgres" db is a "public" (doesn"t typically require auth/grants to
    # connect to) db that typically exists for all postgres installations; the
    # adapter uses it to create/drop other databases
    def public_connect_hash
      @public_connect_hash ||= connect_hash.merge({
        "database" => "postgres",
        "schema_search_path" => "public",
      })
    end

    def create_db
      ActiveRecord::Base.establish_connection(public_connect_hash)
      ActiveRecord::Base.connection.create_database(
        database,
        connect_hash,
      )
      ActiveRecord::Base.establish_connection(connect_hash)
    end

    def drop_db
      begin
        ActiveRecord::Base.establish_connection(public_connect_hash)
        ActiveRecord::Base.connection.tap do |conn|
          conn.execute(
            "UPDATE pg_catalog.pg_database"\
            " SET datallowconn=false WHERE datname='#{database}'",
          )
          # this SELECT actually runs a command: it terminates all the
          # connections
          # http://www.postgresql.org/docs/9.2/static/functions-admin.html#FUNCTIONS-ADMIN-SIGNAL-TABLE
          conn.execute "SELECT pg_terminate_backend(pid)"\
                       " FROM pg_stat_activity WHERE datname='#{database}'"
          conn.execute "DROP DATABASE IF EXISTS #{database}"
        end
      rescue PG::Error => ex
        raise ex unless ex.message =~ /does not exist/
      end
    end

    def drop_tables
      ActiveRecord::Base.connection.tap do |conn|
        tables = conn.execute "SELECT table_name"\
                              " FROM information_schema.tables"\
                              " WHERE table_schema = 'public';"
        tables.each do |row|
          conn.execute "DROP TABLE #{row["table_name"]} CASCADE"
        end
      end
    end

    def load_sql_schema
      require "scmd"
      cmd_str = "psql -f \"#{sql_schema_path}\" #{database}"
      cmd = Scmd.new(cmd_str, env: env_var_hash).tap(&:run)
      raise "Error loading database" unless cmd.success?
    end

    def dump_sql_schema
      require "scmd"
      cmd_str =
        "pg_dump -i -s -x -O -f \"#{sql_schema_path}\" #{database}"
      cmd = Scmd.new(cmd_str, env: env_var_hash).tap(&:run)
      raise "Error dumping database" unless cmd.success?
    end

    private

    def validate!
      if database =~ /\W/
        raise(
          Ardb::ConfigurationError,
          "database value must not contain non-word characters. "\
          "Given: #{database.inspect}.",
        )
      end
    end

    def env_var_hash
      @env_var_hash ||= {
        "PGHOST" => connect_hash["host"],
        "PGPORT" => connect_hash["port"],
        "PGUSER" => connect_hash["username"],
        "PGPASSWORD" => connect_hash["password"],
      }
    end
  end
end
