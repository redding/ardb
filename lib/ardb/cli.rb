require 'ardb'
require 'ardb/clirb'

module Ardb

  class CLI

    class InvalidCommand;           end
    class ConnectCommand;           end
    class CreateCommand;            end
    class DropCommand;              end
    class MigrateCommand;           end
    class GenerateMigrationCommand; end
    COMMANDS = Hash.new{ |h, k| InvalidCommand.new(k) }.tap do |h|
      h['connect']            = ConnectCommand
      h['create']             = CreateCommand
      h['drop']               = DropCommand
      h['migrate']            = MigrateCommand
      h['generate-migration'] = GenerateMigrationCommand
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
        $LOAD_PATH.push(Dir.pwd) unless $LOAD_PATH.include?(Dir.pwd)
        Ardb.init(false) # don't establish a connection

        cmd_name = args.shift
        cmd = COMMANDS[cmd_name].new(args)
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

      def run
        @clirb.parse!(@argv)
        raise CLIRB::HelpExit if @clirb.args.empty? || @name.to_s.empty?
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
        @adapter = Ardb::Adapter.send(Ardb.config.adapter)
      end

      def run
        @clirb.parse!(@argv)
        begin
          Ardb.init
          @adapter.connect_db
          @stdout.puts "connected to #{Ardb.config.adapter} db `#{Ardb.config.database}`"
        rescue StandardError => e
          @stderr.puts e
          @stderr.puts e.backtrace.join("\n")
          @stderr.puts "error connecting to #{Ardb.config.database.inspect} database " \
                       "with #{Ardb.config.activerecord_connect_hash.inspect}"
          raise CommandExitError
        end
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
        @adapter = Ardb::Adapter.send(Ardb.config.adapter)
      end

      def run
        @clirb.parse!(@argv)
        begin
          @adapter.create_db
          @stdout.puts "created #{Ardb.config.adapter} db `#{Ardb.config.database}`"
        rescue StandardError => e
          @stderr.puts e
          @stderr.puts "error creating #{Ardb.config.database.inspect} database"
          raise CommandExitError
        end
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
        @adapter = Ardb::Adapter.send(Ardb.config.adapter)
      end

      def run
        @clirb.parse!(@argv)
        begin
          @adapter.drop_db
          @stdout.puts "dropped #{Ardb.config.adapter} db `#{Ardb.config.database}`"
        rescue StandardError => e
          @stderr.puts e
          @stderr.puts "error dropping #{Ardb.config.database.inspect} database"
          raise CommandExitError
        end
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
        @adapter = Ardb::Adapter.send(Ardb.config.adapter)
      end

      def run
        @clirb.parse!(@argv)
        begin
          Ardb.init
          @adapter.migrate_db
          @adapter.dump_schema unless ENV['ARDB_MIGRATE_NO_SCHEMA']
        rescue StandardError => e
          @stderr.puts e
          @stderr.puts e.backtrace.join("\n")
          @stderr.puts "error migrating #{Ardb.config.database.inspect} database"
          raise CommandExitError
        end
      end

      def help
        "Usage: ardb migrate [options]\n\n" \
        "Options: #{@clirb}"
      end

    end

    class GenerateMigrationCommand

      attr_reader :clirb

      def initialize(argv, stdout = nil, stderr = nil)
        @argv   = argv
        @stdout = stdout || $stdout
        @stderr = stderr || $stderr

        @clirb = Ardb::CLIRB.new
      end

      def run
        @clirb.parse!(@argv)
        begin
          require "ardb/migration"
          path = Ardb::Migration.new(@clirb.args.first).save!.file_path
          @stdout.puts "generated #{path}"
        rescue Ardb::Migration::NoIdentifierError => exception
          error = ArgumentError.new("MIGRATION-NAME must be provided")
          error.set_backtrace(exception.backtrace)
          raise error
        rescue StandardError => e
          @stderr.puts e
          @stderr.puts e.backtrace.join("\n")
          @stderr.puts "error generating migration"
          raise CommandExitError
        end
      end

      def help
        "Usage: ardb generate-migration [options] MIGRATION-NAME\n\n" \
        "Options: #{@clirb}"
      end

    end

  end

end
