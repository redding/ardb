require 'ardb'
require 'ardb/clirb'

module Ardb

  class CLI

    class InvalidCommand; end
    COMMANDS = Hash.new{ |h, k| InvalidCommand.new(k) }.tap do |h|
    end

    def self.run(args)
      self.new.run(args)
    end

    def initialize(kernel = nil, stdout = nil, stderr = nil)
      @kernel = kernel || Kernel
      @stdout = stdout || $stdout
      @stderr = stderr || $stderr
    end

    def run(args)
      begin
        cmd_name = args.shift
        cmd = COMMANDS[cmd_name].new(args)
        cmd.init
        cmd.run
      rescue CLIRB::HelpExit
        @stdout.puts cmd.help
      rescue CLIRB::VersionExit
        @stdout.puts Ardb::VERSION
      rescue CLIRB::Error, ArgumentError, InvalidCommandError => exception
        display_debug(exception)
        @stderr.puts "#{exception.message}\n\n"
        @stdout.puts cmd.help
        @kernel.exit 1
      rescue CommandExitError
        @kernel.exit 1
      rescue StandardError => exception
        @stderr.puts "#{exception.class}: #{exception.message}"
        @stderr.puts exception.backtrace.join("\n")
        @kernel.exit 1
      end
      @kernel.exit 0
    end

    private

    def display_debug(exception)
      if ENV['DEBUG']
        @stderr.puts "#{exception.class}: #{exception.message}"
        @stderr.puts exception.backtrace.join("\n")
      end
    end

    InvalidCommandError = Class.new(ArgumentError)
    CommandExitError    = Class.new(RuntimeError)

    class InvalidCommand

      attr_reader :name, :argv, :clirb

      def initialize(name)
        @name  = name
        @argv  = []
        @clirb = Ardb::CLIRB.new
      end

      def new(args)
        @argv = [@name, args].flatten.compact
        self
      end

      def init
        @clirb.parse!(@argv)
        raise CLIRB::HelpExit if @clirb.args.empty? || @name.to_s.empty?
      end

      def run
        raise InvalidCommandError, "'#{self.name}' is not a command."
      end

      def help
        "Usage: ardb [COMMAND] [options]\n\n" \
        "Commands: #{COMMANDS.keys.sort.join(', ')}\n" \
        "Options: #{@clirb}"
      end

    end

    class ConnectCommand

      attr_reader :clirb

      def initialize(argv, stdout = nil, stderr = nil)
        @argv   = argv
        @stdout = stdout || $stdout
        @stderr = stderr || $stderr

        @clirb   = Ardb::CLIRB.new
        @adapter = Ardb::Adapter.send(Ardb.config.db.adapter)
      end

      def init
        @clirb.parse!(@argv)
      end

      def run
        Ardb.init
        @adapter.connect_db
        @stdout.puts "connected to #{Ardb.config.db.adapter} db `#{Ardb.config.db.database}`"
      rescue StandardError => e
        @stderr.puts e
        @stderr.puts e.backtrace.join("\n")
        @stderr.puts "error connecting to #{Ardb.config.db.database.inspect} database " \
                     "with #{Ardb.config.db_settings.inspect}"
        raise CommandExitError
      end

      def help
        "Usage: ardb connect [options]\n\n" \
        "Options: #{@clirb}"
      end

    end

    class CreateCommand

      attr_reader :clirb

      def initialize(argv, stdout = nil, stderr = nil)
        @argv   = argv
        @stdout = stdout || $stdout
        @stderr = stderr || $stderr

        @clirb   = Ardb::CLIRB.new
        @adapter = Ardb::Adapter.send(Ardb.config.db.adapter)
      end

      def init
        @clirb.parse!(@argv)
      end

      def run
        Ardb.init(false)
        @adapter.create_db
        @stdout.puts "created #{Ardb.config.db.adapter} db `#{Ardb.config.db.database}`"
      rescue StandardError => e
        @stderr.puts e
        @stderr.puts "error creating #{Ardb.config.db.database.inspect} database"
        raise CommandExitError
      end

      def help
        "Usage: ardb create [options]\n\n" \
        "Options: #{@clirb}"
      end

    end

    class DropCommand

      attr_reader :clirb

      def initialize(argv, stdout = nil, stderr = nil)
        @argv   = argv
        @stdout = stdout || $stdout
        @stderr = stderr || $stderr

        @clirb   = Ardb::CLIRB.new
        @adapter = Ardb::Adapter.send(Ardb.config.db.adapter)
      end

      def init
        @clirb.parse!(@argv)
      end

      def run
        Ardb.init(false)
        @adapter.drop_db
        @stdout.puts "dropped #{Ardb.config.db.adapter} db `#{Ardb.config.db.database}`"
      rescue StandardError => e
        @stderr.puts e
        @stderr.puts "error dropping #{Ardb.config.db.database.inspect} database"
        raise CommandExitError
      end

      def help
        "Usage: ardb drop [options]\n\n" \
        "Options: #{@clirb}"
      end

    end

    class MigrateCommand

      attr_reader :clirb

      def initialize(argv, stdout = nil, stderr = nil)
        @argv   = argv
        @stdout = stdout || $stdout
        @stderr = stderr || $stderr

        @clirb   = Ardb::CLIRB.new
        @adapter = Ardb::Adapter.send(Ardb.config.db.adapter)
      end

      def init
        @clirb.parse!(@argv)
      end

      def run
        Ardb.init
        @adapter.migrate_db
        @adapter.dump_schema unless ENV['ARDB_MIGRATE_NO_SCHEMA']
      rescue StandardError => e
        @stderr.puts e
        @stderr.puts e.backtrace.join("\n")
        @stderr.puts "error migrating #{Ardb.config.db.database.inspect} database"
        raise CommandExitError
      end

      def help
        "Usage: ardb migrate [options]\n\n" \
        "Options: #{@clirb}"
      end

    end

  end

end
