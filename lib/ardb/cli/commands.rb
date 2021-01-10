# frozen_string_literal: true

require "ardb"
require "ardb/cli/clirb"
require "much-mixin"

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

    def new
      self
    end

    def run(argv)
      @clirb.parse!([@name, argv].flatten.compact)
      raise CLIRB::HelpExit if @name.to_s.empty?
      raise InvalidCommandError, "\"#{name}\" is not a command."
    end

    def command_help
      "Usage: ardb [COMMAND] [options]\n\n" \
      "Options: #{@clirb}\n" \
      "Commands:\n" \
      "#{COMMANDS.to_s.split("\n").map{ |l| "  #{l}" }.join("\n")}\n"
    end
  end

  module ValidCommand
    include MuchMixin

    mixin_class_methods do
      def command_name
        raise NotImplementedError
      end

      def command_summary
        ""
      end
    end

    mixin_instance_methods do
      def initialize(&clirb_build)
        @clirb = CLIRB.new(&clirb_build)
      end

      def clirb
        @clirb
      end

      def run(argv, stdout = nil, stderr = nil)
        @clirb.parse!(argv)
        @stdout = stdout || $stdout
        @stderr = stderr || $stderr
      end

      def command_name
        self.class.command_name
      end

      def command_summary
        self.class.command_summary
      end

      def command_help
        "Usage: ardb #{command_name} [options]\n\n" \
        "Options: #{clirb}\n" \
        "Description:\n" \
        "  #{command_summary}"
      end
    end
  end

  class ConnectCommand
    include ValidCommand

    def self.command_name
      "connect"
    end

    def self.command_summary
      "Connect to the configured DB"
    end

    def run(argv, *args)
      super

      begin
        Ardb.init(false)
        Ardb.adapter.connect_db
        @stdout.puts(
          "connected to #{Ardb.config.adapter} "\
          "db #{Ardb.config.database.inspect}",
        )
      rescue ActiveRecord::NoDatabaseError
        @stderr.puts(
          "error: database #{Ardb.config.database.inspect} does not exist",
        )
      rescue => ex
        @stderr.puts ex
        @stderr.puts ex.backtrace.join("\n")
        @stderr.puts(
          "error connecting to #{Ardb.config.database.inspect} database " \
          "with #{Ardb.config.activerecord_connect_hash.inspect}",
        )
        raise CommandExitError
      end
    end
  end

  class CreateCommand
    include ValidCommand

    def self.command_name
      "create"
    end

    def self.command_summary
      "Create the configured DB"
    end

    def run(argv, *args)
      super

      begin
        Ardb.init(false)
        Ardb.adapter.create_db
        @stdout.puts(
          "created #{Ardb.config.adapter} db #{Ardb.config.database.inspect}",
        )
      rescue ActiveRecord::StatementInvalid
        @stderr.puts(
          "error: database #{Ardb.config.database.inspect} already exists",
        )
      rescue => ex
        @stderr.puts ex
        @stderr.puts "error creating #{Ardb.config.database.inspect} database"
        raise CommandExitError
      end
    end
  end

  class DropCommand
    include ValidCommand

    def self.command_name
      "drop"
    end

    def self.command_summary
      "Drop the configured DB"
    end

    def run(argv, *args)
      super

      begin
        Ardb.init(true)
        Ardb.adapter.drop_db
        @stdout.puts(
          "dropped #{Ardb.config.adapter} db #{Ardb.config.database.inspect}",
        )
      rescue ActiveRecord::NoDatabaseError
        @stderr.puts(
          "error: database #{Ardb.config.database.inspect} does not exist",
        )
      rescue => ex
        @stderr.puts ex
        @stderr.puts "error dropping #{Ardb.config.database.inspect} database"
        raise CommandExitError
      end
    end
  end

  class GenerateMigrationCommand
    include ValidCommand

    def self.command_name
      "generate-migration"
    end

    def self.command_summary
      "Generate a MIGRATION-NAME migration file"
    end

    def run(argv, *args)
      super

      begin
        Ardb.init(false)

        require "ardb/migration"
        migration = Ardb::Migration.new(Ardb.config, @clirb.args.first)
        migration.save!
        @stdout.puts "generated #{migration.file_path}"
      rescue Ardb::Migration::NoIdentifierError => ex
        error = ArgumentError.new("MIGRATION-NAME must be provided")
        error.set_backtrace(ex.backtrace)
        raise error
      rescue => ex
        @stderr.puts ex
        @stderr.puts ex.backtrace.join("\n")
        @stderr.puts "error generating migration"
        raise CommandExitError
      end
    end

    def command_help
      "Usage: ardb #{command_name} MIGRATION-NAME [options]\n\n" \
      "Options: #{clirb}\n" \
      "Description:\n" \
      "  #{command_summary}"
    end
  end

  module MigrateCommandBehaviors
    include MuchMixin

    mixin_included do
      include ValidCommand
    end

    mixin_instance_methods do
      def migrate
        raise NotImplementedError
      end

      def run(argv, *args)
        super

        begin
          Ardb.init(true)
          migrate
          Ardb.adapter.dump_schema unless ENV["ARDB_MIGRATE_NO_SCHEMA"]
        rescue ActiveRecord::NoDatabaseError
          @stderr.puts(
            "error: database #{Ardb.config.database.inspect} does not exist",
          )
        rescue => ex
          @stderr.puts ex
          @stderr.puts ex.backtrace.join("\n")
          @stderr.puts(
            "error migrating #{Ardb.config.database.inspect} database",
          )
          raise CommandExitError
        end
      end
    end
  end

  class MigrateCommand
    include MigrateCommandBehaviors

    def self.command_name
      "migrate"
    end

    def self.command_summary
      "Migrate the configured DB"
    end

    def migrate
      Ardb.adapter.migrate_db
    end
  end

  module MigrateStyleBehaviors
    include MuchMixin

    mixin_included do
      include MigrateCommandBehaviors
    end

    mixin_class_methods do
      def command_style
        raise NotImplementedError
      end

      def command_name
        "migrate-#{command_style}"
      end

      def command_summary
        "Migrate the configured DB #{command_style}"
      end
    end

    mixin_instance_methods do
      def migrate
        Ardb.adapter.send(
          "migrate_db_#{self.class.command_style}",
          *migrate_args,
        )
      end

      private

      def migrate_args
        raise NotImplementedError
      end
    end
  end

  module MigrateDirectionBehaviors
    include MuchMixin

    mixin_included do
      include MigrateStyleBehaviors
    end

    mixin_class_methods do
      def command_style
        command_direction
      end

      def command_direction
        raise NotImplementedError
      end
    end

    mixin_instance_methods do
      def initialize
        super do
          option(:target_version, "version to migrate to", value: String)
        end
      end

      private

      def migrate_args
        [@clirb.opts[:target_version]]
      end
    end
  end

  module MigrateStepDirectionBehaviors
    include MuchMixin

    mixin_included do
      include MigrateStyleBehaviors
    end

    mixin_class_methods do
      def command_style
        command_direction
      end

      def command_direction
        raise NotImplementedError
      end
    end

    mixin_instance_methods do
      def initialize
        super do
          option(:steps, "number of migrations to migrate", value: 1)
        end
      end

      private

      def migrate_args
        [@clirb.opts[:steps]]
      end
    end
  end

  class MigrateUpCommand
    include MigrateDirectionBehaviors

    def self.command_direction
      "up"
    end
  end

  class MigrateDownCommand
    include MigrateDirectionBehaviors

    def self.command_direction
      "down"
    end
  end

  class MigrateForwardCommand
    include MigrateStepDirectionBehaviors

    def self.command_direction
      "forward"
    end
  end

  class MigrateBackwardCommand
    include MigrateStepDirectionBehaviors

    def self.command_direction
      "backward"
    end
  end

  class CommandSet
    def initialize(&unknown_cmd_block)
      @lookup    = Hash.new{ |_h, k| unknown_cmd_block.call(k) }
      @names     = []
      @aliases   = {}
      @summaries = {}
    end

    def add(klass)
      begin
        cmd = klass.new
      rescue
        # don"t add any commands you can"t initialize
      else
        @lookup[cmd.command_name] = cmd
        @to_s = nil
        @names << cmd.command_name
        @summaries[cmd.command_name] = cmd.command_summary.to_s
      end
    end

    def remove(klass)
      @lookup.delete(klass.command_name)
      @names.delete(klass.command_name)
      @summaries.delete(klass.command_name)
      @to_s = nil
    end

    def [](cmd_name)
      @lookup[cmd_name]
    end

    def size
      @names.size
    end

    def to_s
      max_name_size = @names.map(&:size).max || 0

      @to_s ||= @names.map{ |n|
        "#{n.ljust(max_name_size)} #{@summaries[n]}"
      }.join("\n")
    end
  end
end
