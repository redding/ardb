require 'active_record'
require 'ardb/runner'

# Note: currently only postgresql adapter supported

class Ardb::Runner::DropCommand

  def run
    begin
      self.send("#{Ardb.config.db.adapter}_cmd").run
      $stdout.puts "Dropped #{Ardb.config.db.adapter} db `#{Ardb.config.db.database}`"
    rescue Exception => e
      $stderr.puts e, *(e.backtrace)
      $stderr.puts "Couldn't drop database for #{Ardb.config.db.to_hash.inspect}"
    end
  end

  def postgresql_cmd
    PostgresqlCommand.new
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
      ActiveRecord::Base.connection.drop_database(@database)
    end
  end

end
