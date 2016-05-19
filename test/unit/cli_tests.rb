require 'assert'
require 'ardb/cli'

require 'ardb/adapter_spy'
require 'ardb/migration'

class Ardb::CLI

  class UnitTests < Assert::Context
    desc "Ardb::CLI"
    setup do
      @kernel_spy = KernelSpy.new
      @stdout = IOSpy.new
      @stderr = IOSpy.new

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

      assert_equal ConnectCommand,           COMMANDS['connect']
      assert_equal CreateCommand,            COMMANDS['create']
      assert_equal DropCommand,              COMMANDS['drop']
      assert_equal MigrateCommand,           COMMANDS['migrate']
      assert_equal GenerateMigrationCommand, COMMANDS['generate-migration']
    end

  end

  class InitTests < UnitTests
    desc "when init"
    setup do
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
      COMMANDS[@command_name] = @command_class

      @command_spy = CommandSpy.new
      Assert.stub(@command_class, :new).with(@argv){ @command_spy }

      @ardb_init_called_with = nil
      Assert.stub(Ardb, :init){ |*args| @ardb_init_called_with = args }

      @invalid_command = InvalidCommand.new(@command_name)
    end
    teardown do
      COMMANDS.delete(@command_name)
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

    should "init Ardb without establishing a connection" do
      assert_equal [false], @ardb_init_called_with
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
      Assert.stub(@command_class, :new).with(@argv){ raise @exception }
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

    should have_readers :name, :argv, :clirb
    should have_imeths :new, :run, :help

    should "know its attrs" do
      assert_equal @name, subject.name
      assert_equal [],    subject.argv

      assert_instance_of Ardb::CLIRB, subject.clirb
    end

    should "set its argv and return itself using `new`" do
      args = [Factory.string, Factory.string]
      result = subject.new(args)
      assert_same subject, result
      assert_equal [@name, args].flatten, subject.argv
    end

    should "parse its argv on run`" do
      assert_raises(Ardb::CLIRB::HelpExit){ subject.new(['--help']).run }
      assert_raises(Ardb::CLIRB::VersionExit){ subject.new(['--version']).run }
    end

    should "raise a help exit if its argv is empty" do
      cmd = @command_class.new([nil, ''].choice)
      assert_raises(Ardb::CLIRB::HelpExit){ cmd.new([]).run }
    end

    should "raise an invalid command error when run" do
      assert_raises(InvalidCommandError){ subject.new([Factory.string]).run }
    end

    should "know its help" do
      exp = "Usage: ardb [COMMAND] [options]\n\n" \
            "Commands: #{COMMANDS.keys.sort.join(', ')}\n" \
            "Options: #{subject.clirb}"
      assert_equal exp, subject.help
    end

  end

  class ConnectCommandTests < UnitTests
    desc "ConnectCommand"
    setup do
      @ardb_init_called = false
      Assert.stub(Ardb, :init){ @ardb_init_called = true }

      @adapter_spy = Ardb::AdapterSpy.new(Ardb.config)
      Assert.stub(Ardb::Adapter, :new){ @adapter_spy }

      @command_class = ConnectCommand
      @cmd = @command_class.new([], @stdout, @stderr)
    end
    subject{ @cmd }

    should have_readers :clirb

    should "know its CLI.RB" do
      assert_instance_of Ardb::CLIRB, subject.clirb
    end

    should "know its help" do
      exp = "Usage: ardb connect [options]\n\n" \
            "Options: #{subject.clirb}"
      assert_equal exp, subject.help
    end

    should "parse its args, init ardb and connect to the db on run" do
      subject.run

      assert_equal [], subject.clirb.args

      assert_true @ardb_init_called
      assert_true @adapter_spy.connect_db_called?

      exp = "connected to #{Ardb.config.adapter} db `#{Ardb.config.database}`\n"
      assert_equal exp, @stdout.read
    end

    should "output any errors and raise an exit error on run" do
      err = StandardError.new(Factory.string)
      err.set_backtrace(Factory.integer(3).times.map{ Factory.path })
      Assert.stub(Ardb, :init){ raise err }

      assert_raises(CommandExitError){ subject.run }
      err_output = @stderr.read

      assert_includes err.to_s,                 err_output
      assert_includes err.backtrace.join("\n"), err_output

      exp = "error connecting to #{Ardb.config.database.inspect} database " \
            "with #{Ardb.config.activerecord_connect_hash.inspect}"
      assert_includes exp, err_output
    end

  end

  class CreateCommandTests < UnitTests
    desc "CreateCommand"
    setup do
      @adapter_spy = Ardb::AdapterSpy.new(Ardb.config)
      Assert.stub(Ardb::Adapter, :new){ @adapter_spy }

      @command_class = CreateCommand
      @cmd = @command_class.new([], @stdout, @stderr)
    end
    subject{ @cmd }

    should have_readers :clirb

    should "know its CLI.RB" do
      assert_instance_of Ardb::CLIRB, subject.clirb
    end

    should "know its help" do
      exp = "Usage: ardb create [options]\n\n" \
            "Options: #{subject.clirb}"
      assert_equal exp, subject.help
    end

    should "parse its args and create the db on run" do
      subject.run

      assert_equal [], subject.clirb.args
      assert_true @adapter_spy.create_db_called?

      exp = "created #{Ardb.config.adapter} db `#{Ardb.config.database}`\n"
      assert_equal exp, @stdout.read
    end

    should "output any errors and raise an exit error on run" do
      err = StandardError.new(Factory.string)
      Assert.stub(@adapter_spy, :create_db){ raise err }

      assert_raises(CommandExitError){ subject.run }
      err_output = @stderr.read

      assert_includes err.to_s, err_output
      exp = "error creating #{Ardb.config.database.inspect} database"
      assert_includes exp, err_output
    end

  end

  class DropCommandTests < UnitTests
    desc "DropCommand"
    setup do
      @adapter_spy = Ardb::AdapterSpy.new(Ardb.config)
      Assert.stub(Ardb::Adapter, :new){ @adapter_spy }

      @command_class = DropCommand
      @cmd = @command_class.new([], @stdout, @stderr)
    end
    subject{ @cmd }

    should have_readers :clirb

    should "know its CLI.RB" do
      assert_instance_of Ardb::CLIRB, subject.clirb
    end

    should "know its help" do
      exp = "Usage: ardb drop [options]\n\n" \
            "Options: #{subject.clirb}"
      assert_equal exp, subject.help
    end

    should "parse its args and drop the db on run" do
      subject.run

      assert_equal [], subject.clirb.args
      assert_true @adapter_spy.drop_db_called?

      exp = "dropped #{Ardb.config.adapter} db `#{Ardb.config.database}`\n"
      assert_equal exp, @stdout.read
    end

    should "output any errors and raise an exit error on run" do
      err = StandardError.new(Factory.string)
      Assert.stub(@adapter_spy, :drop_db){ raise err }

      assert_raises(CommandExitError){ subject.run }
      err_output = @stderr.read

      assert_includes err.to_s, err_output
      exp = "error dropping #{Ardb.config.database.inspect} database"
      assert_includes exp, err_output
    end

  end

  class MigrateCommandTests < UnitTests
    desc "MigrateCommand"
    setup do
      Assert.stub(Ardb, :init){ @ardb_init_called = true }

      @adapter_spy = Ardb::AdapterSpy.new(Ardb.config)
      Assert.stub(Ardb::Adapter, :new){ @adapter_spy }

      @command_class = MigrateCommand
      @cmd = @command_class.new([], @stdout, @stderr)
    end
    subject{ @cmd }

    should have_readers :clirb

    should "know its CLI.RB" do
      assert_instance_of Ardb::CLIRB, subject.clirb
    end

    should "know its help" do
      exp = "Usage: ardb migrate [options]\n\n" \
            "Options: #{subject.clirb}"
      assert_equal exp, subject.help
    end

    should "parse its args, init ardb and migrate the db, dump schema on run" do
      subject.run

      assert_equal [], subject.clirb.args

      assert_true @ardb_init_called
      assert_true @adapter_spy.migrate_db_called?
      assert_true @adapter_spy.dump_schema_called?
    end

    should "init ardb and only migrate on run with no schema dump env var set" do
      current_no_schema = ENV['ARDB_MIGRATE_NO_SCHEMA']
      ENV['ARDB_MIGRATE_NO_SCHEMA'] = 'yes'
      subject.run
      ENV['ARDB_MIGRATE_NO_SCHEMA'] = current_no_schema

      assert_true @ardb_init_called
      assert_true @adapter_spy.migrate_db_called?
      assert_false @adapter_spy.dump_schema_called?
    end

    should "output any errors and raise an exit error on run" do
      err = StandardError.new(Factory.string)
      err.set_backtrace(Factory.integer(3).times.map{ Factory.path })
      Assert.stub(Ardb, :init){ raise err }

      assert_raises(CommandExitError){ subject.run }
      err_output = @stderr.read

      assert_includes err.to_s,                 err_output
      assert_includes err.backtrace.join("\n"), err_output

      exp = "error migrating #{Ardb.config.database.inspect} database"
      assert_includes exp, err_output
    end

  end

  class GenerateMigrationCommandTests < UnitTests
    desc "GenerateMigrationCommand"
    setup do
      @migration_spy   = nil
      @migration_class = Ardb::Migration
      Assert.stub(@migration_class, :new) do |*args|
        @migration_spy = MigrationSpy.new(*args)
      end

      @command_class = GenerateMigrationCommand
      @identifier    = Factory.migration_id
      @cmd = @command_class.new([@identifier], @stdout, @stderr)
    end
    subject{ @cmd }

    should have_readers :clirb

    should "know its CLI.RB" do
      assert_instance_of Ardb::CLIRB, subject.clirb
    end

    should "know its help" do
      exp = "Usage: ardb generate-migration [options] MIGRATION-NAME\n\n" \
            "Options: #{subject.clirb}"
      assert_equal exp, subject.help
    end

    should "parse its args and save a migration for the identifier on run" do
      subject.run

      assert_equal [@identifier], subject.clirb.args
      assert_equal @identifier,   @migration_spy.identifier
      assert_true @migration_spy.save_called

      exp = "generated #{@migration_spy.file_path}\n"
      assert_equal exp, @stdout.read
    end

    should "re-raise a specific argument error on migration 'no identifer' errors" do
      Assert.stub(@migration_class, :new) { raise Ardb::Migration::NoIdentifierError }
      err = nil
      begin
        cmd = @command_class.new([])
        cmd.run
      rescue ArgumentError => err
      end

      assert_not_nil err
      exp = "MIGRATION-NAME must be provided"
      assert_equal exp, err.message
      assert_not_empty err.backtrace
    end

    should "output any errors and raise an exit error on run" do
      err = StandardError.new(Factory.string)
      err.set_backtrace(Factory.integer(3).times.map{ Factory.path })
      Assert.stub(@migration_class, :new){ raise err }

      assert_raises(CommandExitError){ subject.run }
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
    attr_reader :run_called

    def initialize
      @run_called = false
    end

    def run
      @run_called = true
    end

    def help
      Factory.text
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
