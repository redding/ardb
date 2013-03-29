require 'ardb'

module Ardb; end
class Ardb::Runner
  UnknownCmdError = Class.new(ArgumentError)

  attr_reader :cmd, :cmd_args, :opts

  def initialize(args, opts)
    @opts = opts
    @cmd = args.shift || ""
    @cmd_args = args

    @opts['root_path'] ||= Dir.pwd
  end

  def run
    Ardb.config.root_path = opts.delete('root_path')

    case @cmd
    when 'null'
      NullCommand.new.run
    else
      raise UnknownCmdError, "Unknown command `#{@cmd}`"
    end
  end

  class NullCommand
    def run
      # if this was a real command it would do something here
    end
  end

end
