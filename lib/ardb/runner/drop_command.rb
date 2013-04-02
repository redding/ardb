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
      raise Ardb::Runner::CmdFail
    end
  end

end
