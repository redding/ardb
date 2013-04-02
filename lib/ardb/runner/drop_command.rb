require 'active_record'
require 'ardb/runner'

class Ardb::Runner::DropCommand

  def initialize
    @adapter = Ardb::Adapter.send(Ardb.config.db.adapter)
  end

  def run
    begin
      @adapter.drop_db
      $stdout.puts "dropped #{Ardb.config.db.adapter} db `#{Ardb.config.db.database}`"
    rescue Ardb::Runner::CmdError => e
      raise e
    rescue Exception => e
      $stderr.puts e, *(e.backtrace)
      $stderr.puts "error dropping #{Ardb.config.db.database.inspect} database"
    end
  end

end
