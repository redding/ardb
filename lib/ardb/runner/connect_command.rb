require 'ardb/runner'

class Ardb::Runner::ConnectCommand

  def run
    begin
      Ardb.init
      $stdout.puts "connected to #{Ardb.config.db.adapter} db `#{Ardb.config.db.database}`"
    rescue Ardb::Runner::CmdError => e
      raise e
    rescue Exception => e
      $stderr.puts e, *e.backtrace
      $stderr.puts "error connecting to #{Ardb.config.db.database.inspect} database"\
                   " with #{Ardb.config.db_settings.inspect}"
      raise Ardb::Runner::CmdFail
    end
  end

end
