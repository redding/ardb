require 'fileutils'
require 'active_record'
require 'ardb/runner'

class Ardb::Runner

  class MigrateCommand

    def initialize(out_io = nil, err_io = nil)
      @out_io = out_io || $stdout
      @err_io = err_io || $stderr
      @adapter = Ardb::Adapter.send(Ardb.config.db.adapter)
    end

    def run
      begin
        Ardb.init
        @adapter.migrate_db
        @adapter.dump_schema unless ENV['ARDB_MIGRATE_NO_SCHEMA']
      rescue Ardb::Runner::CmdError => e
        raise e
      rescue StandardError => e
        @err_io.puts "error migrating #{Ardb.config.db.database.inspect} database"
        @err_io.puts e
        @err_io.puts e.backtrace
        raise Ardb::Runner::CmdFail
      end
    end

  end

end
