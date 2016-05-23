require 'assert'
require 'ardb/cli'

require 'ardb/adapter_spy'
require 'ardb/migration'

class Ardb::CLI

  class UnitTests < Assert::Context
    desc "Ardb::CLI"
    setup do
      @cli_class = Ardb::CLI
    end
    subject{ @cli_class }

    should have_imeths :run

    should "build and run an instance of itself using `run`" do
      cli_spy = CLISpy.new
      Assert.stub(subject, :new).with{ cli_spy }

      args = [Factory.string]
      subject.run(args)
      assert_equal args, cli_spy.run_called_with
    end

    should "know its commands" do
      assert_equal 5, COMMANDS.size

      assert_instance_of InvalidCommand, COMMANDS[Factory.string]
      assert_instance_of ConnectCommand,           COMMANDS['connect']
      assert_instance_of CreateCommand,            COMMANDS['create']
      assert_instance_of DropCommand,              COMMANDS['drop']
      assert_instance_of MigrateCommand,           COMMANDS['migrate']
      assert_instance_of GenerateMigrationCommand, COMMANDS['generate-migration']
    end

  end

  class InitTests < UnitTests
    desc "when init"
    setup do
      @kernel_spy = KernelSpy.new
      @stdout     = IOSpy.new
      @stderr     = IOSpy.new

      @cli = @cli_class.new(@kernel_spy, @stdout, @stderr)
    end
    subject{ @cli }

    should have_imeths :run

  end

  class RunSetupTests < InitTests
    setup do
      @command_name = Factory.string
      @argv = [@command_name, Factory.string]

      @command_class = Class.new
      @command_spy  = CommandSpy.new
      Assert.stub(@command_class, :new){ @command_spy }
      COMMANDS.add(@command_class, @command_name)

      @invalid_command = InvalidCommand.new(@command_name)
    end
    teardown do
      COMMANDS.remove(@command_name)
    end

  end

  class RunTests < RunSetupTests
    desc "and run"
    setup do
      @cli.run(@argv)
    end

    should "push the pwd onto the load path" do
      assert_includes Dir.pwd, $LOAD_PATH
    end

    should "have run the command" do
      assert_true @command_spy.run_called
    end

    should "have successfully exited" do
      assert_equal 0, @kernel_spy.exit_status
    end

  end

  class RunWithNoArgsTests < RunSetupTests
    desc "and run with no args"
    setup do
      @cli.run([])
    end

    should "output the invalid command's help" do
      assert_equal @invalid_command.help, @stdout.read
      assert_empty @stderr.read
    end

    should "have successfully exited" do
      assert_equal 0, @kernel_spy.exit_status
    end

  end

  class RunWithInvalidCommandTests < RunSetupTests
    desc "and run with an invalid command"
    setup do
      @name = Factory.string
      @argv.unshift(@name)
      @cli.run(@argv)
    end

    should "output that it is invalid and output the invalid command's help" do
      exp = "'#{@name}' is not a command.\n\n"
      assert_equal exp, @stderr.read
      assert_equal @invalid_command.help, @stdout.read
    end

    should "have unsuccessfully exited" do
      assert_equal 1, @kernel_spy.exit_status
    end

  end

  class RunWithCommandExitErrorTests < RunSetupTests
    desc "and run with a command that error exits"
    setup do
      Assert.stub(@command_spy, :run){ raise CommandExitError }
      @cli.run(@argv)
    end

    should "have unsuccessfully exited with no stderr output" do
      assert_equal 1, @kernel_spy.exit_status
      assert_empty @stderr.read
    end

  end

  class RunWithHelpTests < RunSetupTests
    desc "and run with the help switch"
    setup do
      @cli.run([ '--help' ])
    end

    should "output the invalid command's help" do
      assert_equal @invalid_command.help, @stdout.read
      assert_empty @stderr.read
    end

    should "have successfully exited" do
      assert_equal 0, @kernel_spy.exit_status
    end

  end

  class RunWithVersionTests < RunSetupTests
    desc "and run with the version switch"
    setup do
      @cli.run([ '--version' ])
    end

    should "output its version" do
      assert_equal "#{Ardb::VERSION}\n", @stdout.read
      assert_empty @stderr.read
    end

    should "have successfully exited" do
      assert_equal 0, @kernel_spy.exit_status
    end

  end

  class RunWithErrorTests < RunSetupTests
    setup do
      @exception = RuntimeError.new(Factory.string)
      Assert.stub(@command_spy, :run){ raise @exception }
      @cli.run(@argv)
    end

    should "have output an error message" do
      exp = "#{@exception.class}: #{@exception.message}\n" \
            "#{@exception.backtrace.join("\n")}\n"
      assert_equal exp, @stderr.read
      assert_empty @stdout.read
    end

    should "have unsuccessfully exited" do
      assert_equal 1, @kernel_spy.exit_status
    end

  end

  class InvalidCommandTests < UnitTests
    desc "InvalidCommand"
    setup do
      @name = Factory.string
      @command_class = InvalidCommand
      @cmd = @command_class.new(@name)
    end
    subject{ @cmd }

    should have_readers :name, :clirb
    should have_imeths :new, :run, :help

    should "know its attrs" do
      assert_equal @name, subject.name
      assert_instance_of CLIRB, subject.clirb
    end

    should "set its argv and return itself using `new`" do
      assert_same subject, subject.new
    end

    should "parse its argv on run" do
      assert_raises(CLIRB::HelpExit){ subject.new.run([ '--help' ]) }
      assert_raises(CLIRB::VersionExit){ subject.new.run([ '--version' ]) }
    end

    should "raise a help exit if its name is empty" do
      cmd = @command_class.new([nil, ''].sample)
      argv = [Factory.string, Factory.string]
      assert_raises(CLIRB::HelpExit){ cmd.new.run(argv) }
    end

    should "raise an invalid command error when run" do
      assert_raises(InvalidCommandError){ subject.new.run([Factory.string]) }
    end

    should "know its help" do
      exp = "Usage: ardb [COMMAND] [options]\n\n" \
            "Options: #{subject.clirb}\n" \
            "Commands:\n" \
            "#{COMMANDS.to_s.split("\n").map{ |l| "  #{l}" }.join("\n")}\n"
      assert_equal exp, subject.help
    end

  end

  class CommandSetupTests < UnitTests
    setup do
      @stdout, @stderr = IOSpy.new, IOSpy.new

      @ardb_init_called_with = nil
      Assert.stub(Ardb, :init){ |*args| @ardb_init_called_with = args }

      @adapter_spy = Ardb::AdapterSpy.new
      Assert.stub(Ardb, :adapter){ @adapter_spy }
    end
    subject{ @cmd }

  end

  class ValidCommandTests < CommandSetupTests
    desc "ValidCommand"
    setup do
      @command_class = Class.new{ include ValidCommand }
      @cmd = @command_class.new
    end

    should have_imeths :clirb, :run, :summary

    should "know its CLI.RB" do
      assert_instance_of CLIRB, subject.clirb
    end

    should "parse its args when run" do
      argv = Factory.integer(3).times.map{ Factory.string }
      subject.run(argv, @stdout, @stderr)
      assert_equal argv, subject.clirb.args
    end

    should "default its summary" do
      assert_equal '', subject.summary
    end

  end

  class ConnectCommandTests < CommandSetupTests
    desc "ConnectCommand"
    setup do
      @command_class = ConnectCommand
      @cmd = @command_class.new
    end

    should "be a valid command" do
      assert_kind_of ValidCommand, subject
    end

    should "know its summary" do
      exp = "Connect to the configured DB"
      assert_equal exp, subject.summary
    end

    should "know its help" do
      exp = "Usage: ardb connect [options]\n\n" \
            "Options: #{subject.clirb}\n" \
            "Description:\n" \
            "  #{subject.summary}"
      assert_equal exp, subject.help
    end

    should "init ardb and connect to the db when run" do
      subject.run([], @stdout, @stderr)

      assert_equal [false], @ardb_init_called_with
      assert_true @adapter_spy.connect_db_called?

      exp = "connected to #{Ardb.config.adapter} db `#{Ardb.config.database}`\n"
      assert_equal exp, @stdout.read
    end

    should "output any errors and raise an exit error when run" do
      err = StandardError.new(Factory.string)
      err.set_backtrace(Factory.integer(3).times.map{ Factory.path })
      Assert.stub(Ardb, :init){ raise err }

      assert_raises(CommandExitError){ subject.run([], @stdout, @stderr) }
      err_output = @stderr.read

      assert_includes err.to_s,                 err_output
      assert_includes err.backtrace.join("\n"), err_output

      exp = "error connecting to #{Ardb.config.database.inspect} database " \
            "with #{Ardb.config.activerecord_connect_hash.inspect}"
      assert_includes exp, err_output
    end

  end

  class CreateCommandTests < CommandSetupTests
    desc "CreateCommand"
    setup do
      @command_class = CreateCommand
      @cmd = @command_class.new
    end

    should "be a valid command" do
      assert_kind_of ValidCommand, subject
    end

    should "know its summary" do
      exp = "Create the configured DB"
      assert_equal exp, subject.summary
    end

    should "know its help" do
      exp = "Usage: ardb create [options]\n\n" \
            "Options: #{subject.clirb}\n" \
            "Description:\n" \
            "  #{subject.summary}"
      assert_equal exp, subject.help
    end

    should "init ardb and create the db when run" do
      subject.run([], @stdout, @stderr)

      assert_equal [false], @ardb_init_called_with
      assert_true @adapter_spy.create_db_called?

      exp = "created #{Ardb.config.adapter} db `#{Ardb.config.database}`\n"
      assert_equal exp, @stdout.read
    end

    should "output any errors and raise an exit error when run" do
      err = StandardError.new(Factory.string)
      Assert.stub(@adapter_spy, :create_db){ raise err }

      assert_raises(CommandExitError){ subject.run([], @stdout, @stderr) }
      err_output = @stderr.read

      assert_includes err.to_s, err_output
      exp = "error creating #{Ardb.config.database.inspect} database"
      assert_includes exp, err_output
    end

  end

  class DropCommandTests < CommandSetupTests
    desc "DropCommand"
    setup do
      @command_class = DropCommand
      @cmd = @command_class.new
    end

    should "be a valid command" do
      assert_kind_of ValidCommand, subject
    end

    should "know its summary" do
      exp = "Drop the configured DB"
      assert_equal exp, subject.summary
    end

    should "know its help" do
      exp = "Usage: ardb drop [options]\n\n" \
            "Options: #{subject.clirb}\n" \
            "Description:\n" \
            "  #{subject.summary}"
      assert_equal exp, subject.help
    end

    should "init ardb and drop the db when run" do
      subject.run([], @stdout, @stderr)

      assert_equal [true], @ardb_init_called_with
      assert_true @adapter_spy.drop_db_called?

      exp = "dropped #{Ardb.config.adapter} db `#{Ardb.config.database}`\n"
      assert_equal exp, @stdout.read
    end

    should "output any errors and raise an exit error when run" do
      err = StandardError.new(Factory.string)
      Assert.stub(@adapter_spy, :drop_db){ raise err }

      assert_raises(CommandExitError){ subject.run([], @stdout, @stderr) }
      err_output = @stderr.read

      assert_includes err.to_s, err_output
      exp = "error dropping #{Ardb.config.database.inspect} database"
      assert_includes exp, err_output
    end

  end

  class MigrateCommandTests < CommandSetupTests
    desc "MigrateCommand"
    setup do
      @orig_env_var_migrate_no_schema = ENV['ARDB_MIGRATE_NO_SCHEMA']
      @command_class = MigrateCommand
      @cmd = @command_class.new
    end
    teardown do
      ENV['ARDB_MIGRATE_NO_SCHEMA'] = @orig_env_var_migrate_no_schema
    end

    should "be a valid command" do
      assert_kind_of ValidCommand, subject
    end

    should "know its summary" do
      exp = "Migrate the configured DB"
      assert_equal exp, subject.summary
    end

    should "know its help" do
      exp = "Usage: ardb migrate [options]\n\n" \
            "Options: #{subject.clirb}\n" \
            "Description:\n" \
            "  #{subject.summary}"
      assert_equal exp, subject.help
    end

    should "init ardb and migrate the db, dump schema when run" do
      subject.run([], @stdout, @stderr)

      assert_equal [true], @ardb_init_called_with
      assert_true @adapter_spy.migrate_db_called?
      assert_true @adapter_spy.dump_schema_called?
    end

    should "init ardb and only migrate when run with no schema dump env var set" do
      ENV['ARDB_MIGRATE_NO_SCHEMA'] = 'yes'
      subject.run([], @stdout, @stderr)

      assert_equal [true], @ardb_init_called_with
      assert_true @adapter_spy.migrate_db_called?
      assert_false @adapter_spy.dump_schema_called?
    end

    should "output any errors and raise an exit error when run" do
      err = StandardError.new(Factory.string)
      err.set_backtrace(Factory.integer(3).times.map{ Factory.path })
      Assert.stub(Ardb, :init){ raise err }

      assert_raises(CommandExitError){ subject.run([], @stdout, @stderr) }
      err_output = @stderr.read

      assert_includes err.to_s,                 err_output
      assert_includes err.backtrace.join("\n"), err_output

      exp = "error migrating #{Ardb.config.database.inspect} database"
      assert_includes exp, err_output
    end

  end

  class GenerateMigrationCommandTests < CommandSetupTests
    desc "GenerateMigrationCommand"
    setup do
      @identifier = Factory.migration_id

      @migration_spy   = nil
      @migration_class = Ardb::Migration
      Assert.stub(@migration_class, :new) do |*args|
        @migration_spy = MigrationSpy.new(*args)
      end

      @command_class = GenerateMigrationCommand
      @cmd = @command_class.new
    end

    should "be a valid command" do
      assert_kind_of ValidCommand, subject
    end

    should "know its summary" do
      exp = "Generate a migration file given a MIGRATION-NAME"
      assert_equal exp, subject.summary
    end

    should "know its help" do
      exp = "Usage: ardb generate-migration [options] MIGRATION-NAME\n\n" \
            "Options: #{subject.clirb}\n" \
            "Description:\n" \
            "  #{subject.summary}"
      assert_equal exp, subject.help
    end

    should "init ardb and save a migration for the identifier when run" do
      subject.run([@identifier], @stdout, @stderr)

      assert_equal [false],     @ardb_init_called_with
      assert_equal @identifier, @migration_spy.identifier
      assert_true @migration_spy.save_called

      exp = "generated #{@migration_spy.file_path}\n"
      assert_equal exp, @stdout.read
    end

    should "re-raise a specific argument error on migration 'no identifer' errors" do
      Assert.stub(@migration_class, :new){ raise Ardb::Migration::NoIdentifierError }
      err = nil
      begin
        cmd = @command_class.new
        cmd.run([])
      rescue ArgumentError => err
      end

      assert_not_nil err
      exp = "MIGRATION-NAME must be provided"
      assert_equal exp, err.message
      assert_not_empty err.backtrace
    end

    should "output any errors and raise an exit error when run" do
      err = StandardError.new(Factory.string)
      err.set_backtrace(Factory.integer(3).times.map{ Factory.path })
      Assert.stub(@migration_class, :new){ raise err }

      assert_raises(CommandExitError){ subject.run([@identifier], @stdout, @stderr) }
      err_output = @stderr.read

      assert_includes err.to_s,                 err_output
      assert_includes err.backtrace.join("\n"), err_output

      exp = "error generating migration"
      assert_includes exp, err_output
    end

  end

  class CLISpy
    attr_reader :run_called_with

    def initialize
      @run_called_with = nil
    end

    def run(args)
      @run_called_with = args
    end
  end

  class CommandSpy
    attr_reader :argv, :stdout, :stderr, :run_called

    def initialize
      @argv = nil
      @stdout, @stderr = nil, nil
      @run_called = false
    end

    def run(argv, stdout = nil, stderr = nil)
      @argv = argv
      @stdout, @stderr = stdout, stderr
      @run_called = true
    end

    def summary
      @summary ||= Factory.string
    end

    def help
      @help ||= Factory.text
    end
  end

  class KernelSpy
    attr_reader :exit_status

    def initialize
      @exit_status = nil
    end

    def exit(code)
      @exit_status ||= code
    end
  end

  class IOSpy
    def initialize
      @io = StringIO.new
    end

    def puts(message)
      @io.puts message
    end

    def read
      @io.rewind
      @io.read
    end
  end

  class MigrationSpy
    attr_reader :identifier, :file_path, :save_called

    def initialize(*args)
      @identifier  = args.first
      @file_path   = Factory.path
      @save_called = false
    end

    def save!
      @save_called = true
      self
    end
  end

end
