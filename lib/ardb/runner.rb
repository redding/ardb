require 'ardb'

module Ardb; end
class Ardb::Runner
  UnknownCmdError = Class.new(ArgumentError)

  attr_reader :cmd_name, :cmd_args, :opts, :root_path

  def initialize(args, opts)
    @opts = opts
    @cmd_name = args.shift || ""
    @cmd_args = args
    @root_path = @opts.delete('root_path') || Dir.pwd
  end

  def run
    setup_run
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
    when 'null'
      NullCommand.new.run
    else
      raise UnknownCmdError, "Unknown command `#{@cmd_name}`"
    end
  end

  private

  def setup_run
    Ardb.config.root_path = @root_path
    # TODO: require in a standard file, like config/db.rb??? (for initialization purposes)
    Ardb.validate!
  end

  class NullCommand
    def run
      # if this was a real command it would do something here
    end
  end

end
