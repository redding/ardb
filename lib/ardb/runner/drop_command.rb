require 'active_record'
require 'ardb/runner'

class Ardb::Runner

  class DropCommand

    def initialize(out_io = nil, err_io = nil)
      @out_io = out_io || $stdout
      @err_io = err_io || $stderr
      @adapter = Ardb::Adapter.send(Ardb.config.db.adapter)
    end

    def run
      begin
        @adapter.drop_db
        @out_io.puts "dropped #{Ardb.config.db.adapter} db `#{Ardb.config.db.database}`"
      rescue Ardb::Runner::CmdError => e
        raise e
      rescue StandardError => e
        @err_io.puts e
        @err_io.puts "error dropping #{Ardb.config.db.database.inspect} database"
        raise Ardb::Runner::CmdFail
      end
    end

  end

end
