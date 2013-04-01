require 'active_record'
require 'ardb/runner'

class Ardb::Runner::DropCommand

  def run
    begin
      self.send("#{Ardb.config.db.adapter}_cmd")
      $stdout.puts "Dropped #{Ardb.config.db.adapter} db `#{Ardb.config.db.database}`"
    rescue Ardb::Runner::CmdError => e
      raise e
    rescue Exception => e
      $stderr.puts e, *(e.backtrace)
      $stderr.puts "error dropping #{Ardb.config.db.database.inspect} database"
    end
  end

  def postgresql_cmd
    PostgresqlCommand.new.run
  end

  def sqlite3_cmd
    SqliteCommand.new.run
  end

  class PostgresqlCommand
    attr_reader :config_settings, :database

    def initialize
      @config_settings = Ardb.config.db.to_hash
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

  class SqliteCommand
    attr_reader :config_settings, :database, :db_path

    def initialize
      @config_settings = Ardb.config.db.to_hash
      @database = Ardb.config.db.database
      @db_path = if (path = Pathname.new(@database)).absolute?
        path.to_s
      else
        Ardb.config.root_path.join(path).to_s
      end
    end

    def run
      FileUtils.rm(@db_path) if File.exist?(@db_path)
    end
  end

end
