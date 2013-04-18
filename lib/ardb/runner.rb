require 'ardb'

module Ardb; end
class Ardb::Runner
  UnknownCmdError = Class.new(ArgumentError)
  CmdError = Class.new(RuntimeError)
  CmdFail = Class.new(RuntimeError)

  attr_reader :cmd_name, :cmd_args, :opts

  def initialize(args, opts)
    @opts = opts
    @cmd_name = args.shift || ""
    @cmd_args = args
  end

  def run
    Ardb.init(false) # don't establish a connection

    case @cmd_name
    when 'migrate'
      require 'ardb/runner/migrate_command'
      MigrateCommand.new.run
    when 'generate'
      require 'ardb/runner/generate_command'
      GenerateCommand.new(@cmd_args).run
    when 'create'
      require 'ardb/runner/create_command'
      CreateCommand.new.run
    when 'drop'
      require 'ardb/runner/drop_command'
      DropCommand.new.run
    when 'connect'
      require 'ardb/runner/connect_command'
      ConnectCommand.new.run
    when 'null'
      NullCommand.new.run
    else
      raise UnknownCmdError, "unknown command `#{@cmd_name}`"
    end
  end

  class NullCommand
    def run
      # if this was a real command it would do something here
    end
  end

end
