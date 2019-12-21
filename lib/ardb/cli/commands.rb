require "ardb"
require "ardb/cli/clirb"
require "much-plugin"

module Ardb; end
class Ardb::CLI
  InvalidCommandError = Class.new(ArgumentError)
  CommandExitError    = Class.new(RuntimeError)

  class InvalidCommand
    attr_reader :name, :clirb

    def initialize(name)
      @name  = name
      @clirb = CLIRB.new
    end

    def new; self; end

    def run(argv)
      @clirb.parse!([@name, argv].flatten.compact)
      raise CLIRB::HelpExit if @name.to_s.empty?
      raise InvalidCommandError, "\"#{self.name}\" is not a command."
    end

    def help
      "Usage: ardb [COMMAND] [options]\n\n" \
      "Options: #{@clirb}\n" \
      "Commands:\n" \
      "#{COMMANDS.to_s.split("\n").map{ |l| "  #{l}" }.join("\n")}\n"
    end
  end

  module ValidCommand
    include MuchPlugin

    plugin_instance_methods do
      def initialize(&clirb_build)
        @clirb = CLIRB.new(&clirb_build)
      end

      def clirb; @clirb; end

      def run(argv, stdout = nil, stderr = nil)
        @clirb.parse!(argv)
        @stdout = stdout || $stdout
        @stderr = stderr || $stderr
      end

      def summary
        ""
      end
    end
  end

  class ConnectCommand
    include ValidCommand

    def run(argv, *args)
      super

      Ardb.init(false)
      begin
        Ardb.adapter.connect_db
        @stdout.puts "connected to #{Ardb.config.adapter} db `#{Ardb.config.database}`"
      rescue StandardError => e
        @stderr.puts e
        @stderr.puts e.backtrace.join("\n")
        @stderr.puts "error connecting to #{Ardb.config.database.inspect} database " \
                     "with #{Ardb.config.activerecord_connect_hash.inspect}"
        raise CommandExitError
      end
    end

    def summary
      "Connect to the configured DB"
    end

    def help
      "Usage: ardb connect [options]\n\n" \
      "Options: #{@clirb}\n" \
      "Description:\n" \
      "  #{self.summary}"
    end
  end

  class CreateCommand
    include ValidCommand

    def run(argv, *args)
      super

      Ardb.init(false)
      begin
        Ardb.adapter.create_db
        @stdout.puts "created #{Ardb.config.adapter} db `#{Ardb.config.database}`"
      rescue StandardError => e
        @stderr.puts e
        @stderr.puts "error creating #{Ardb.config.database.inspect} database"
        raise CommandExitError
      end
    end

    def summary
      "Create the configured DB"
    end

    def help
      "Usage: ardb create [options]\n\n" \
      "Options: #{@clirb}\n" \
      "Description:\n" \
      "  #{self.summary}"
    end
  end

  class DropCommand
    include ValidCommand

    def run(argv, *args)
      super

      Ardb.init(true)
      begin
        Ardb.adapter.drop_db
        @stdout.puts "dropped #{Ardb.config.adapter} db `#{Ardb.config.database}`"
      rescue StandardError => e
        @stderr.puts e
        @stderr.puts "error dropping #{Ardb.config.database.inspect} database"
        raise CommandExitError
      end
    end

    def summary
      "Drop the configured DB"
    end

    def help
      "Usage: ardb drop [options]\n\n" \
      "Options: #{@clirb}\n" \
      "Description:\n" \
      "  #{self.summary}"
    end
  end

  class MigrateCommand
    include ValidCommand

    def run(argv, *args)
      super

      Ardb.init(true)
      begin
        Ardb.adapter.migrate_db
        Ardb.adapter.dump_schema unless ENV["ARDB_MIGRATE_NO_SCHEMA"]
      rescue StandardError => e
        @stderr.puts e
        @stderr.puts e.backtrace.join("\n")
        @stderr.puts "error migrating #{Ardb.config.database.inspect} database"
        raise CommandExitError
      end
    end

    def summary
      "Migrate the configured DB"
    end

    def help
      "Usage: ardb migrate [options]\n\n" \
      "Options: #{@clirb}\n" \
      "Description:\n" \
      "  #{self.summary}"
    end
  end

  class GenerateMigrationCommand
    include ValidCommand

    def run(argv, *args)
      super

      Ardb.init(false)
      begin
        require "ardb/migration"
        migration = Ardb::Migration.new(Ardb.config, @clirb.args.first)
        migration.save!
        @stdout.puts "generated #{migration.file_path}"
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

    def summary
      "Generate a migration file given a MIGRATION-NAME"
    end

    def help
      "Usage: ardb generate-migration [options] MIGRATION-NAME\n\n" \
      "Options: #{@clirb}\n" \
      "Description:\n" \
      "  #{self.summary}"
    end
  end

  class CommandSet

    def initialize(&unknown_cmd_block)
      @lookup    = Hash.new{ |h,k| unknown_cmd_block.call(k) }
      @names     = []
      @aliases   = {}
      @summaries = {}
    end

    def add(klass, name, *aliases)
      begin
        cmd = klass.new
      rescue StandardError => err
        # don"t add any commands you can"t init
      else
        ([name] + aliases).each{ |n| @lookup[n] = cmd }
        @to_s = nil
        @names << name
        @aliases[name] = aliases.empty? ? "" : "(#{aliases.join(", ")})"
        @summaries[name] = cmd.summary.to_s.empty? ? "" : "# #{cmd.summary}"
      end
    end

    def remove(name)
      @lookup.delete(name)
      @names.delete(name)
      @aliases.delete(name)
      @to_s = nil
    end

    def [](name)
      @lookup[name]
    end

    def size
      @names.size
    end

    def to_s
      max_name_size  = @names.map{ |n| n.size }.max || 0
      max_alias_size = @aliases.values.map{ |v| v.size }.max || 0

      @to_s ||= @names.map do |n|
        "#{n.ljust(max_name_size)} #{@aliases[n].ljust(max_alias_size)} #{@summaries[n]}"
      end.join("\n")
    end
  end
end
