require 'fileutils'
require 'active_record'
require 'ardb/runner'

class Ardb::Runner::MigrateCommand

  def initialize
    @adapter = Ardb::Adapter.send(Ardb.config.db.adapter)
  end

  def run
    begin
      Ardb.init
      @adapter.migrate_db
      @adapter.dump_schema
    rescue Ardb::Runner::CmdError => e
      raise e
    rescue Exception => e
      $stderr.puts "error migrating #{Ardb.config.db.database.inspect} database"
      $stderr.puts e
      $stderr.puts e.backtrace
      raise Ardb::Runner::CmdFail
    end
  end

end
