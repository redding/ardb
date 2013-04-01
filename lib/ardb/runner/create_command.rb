require 'active_record'
require 'ardb/runner'

# Note: currently only postgresql adapter supported

class Ardb::Runner::CreateCommand

  def run
    begin
      self.send("#{Ardb.config.db.adapter}_cmd")
      $stdout.puts "Created #{Ardb.config.db.adapter} db `#{Ardb.config.db.database}`"
    rescue Ardb::Runner::CmdError => e
      raise e
    rescue Exception => e
      $stderr.puts e, *(e.backtrace)
      $stderr.puts "error creating #{Ardb.config.db.database.inspect} database"
    end
  end

  def postgresql_cmd
    PostgresqlCommand.new.run
  end

  class PostgresqlCommand
    attr_reader :config_settings, :database

    def initialize
      @config_settings  = Ardb.config.db.to_hash
      @database = Ardb.config.db.database
    end

    def run
      ActiveRecord::Base.establish_connection(@config_settings.merge({
        :database           => 'postgres',
        :schema_search_path => 'public'
      }))
      ActiveRecord::Base.connection.create_database(@database, @config_settings)
      ActiveRecord::Base.establish_connection(@config_settings)
    end
  end

end
