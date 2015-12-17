require 'assert'
require 'ardb/cli'

require 'ardb/adapter_spy'

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
      assert_equal 0, COMMANDS.size

      assert_instance_of InvalidCommand, COMMANDS[Factory.string]
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

    should "have init and run the command" do
      assert_true @command_spy.init_called
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
      Assert.stub(@command_spy, :init){ raise CommandExitError }
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
    should have_imeths :new, :init, :run, :help

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

    should "parse its argv when `init`" do
      subject.new([ '--help' ])
      assert_raises(Ardb::CLIRB::HelpExit){ subject.init }
      subject.new([ '--version' ])
      assert_raises(Ardb::CLIRB::VersionExit){ subject.init }
    end

    should "raise a help exit if its argv is empty when `init`" do
      cmd = @command_class.new(nil)
      cmd.new([])
      assert_raises(Ardb::CLIRB::HelpExit){ cmd.init }

      cli = @command_class.new("")
      cli.new([])
      assert_raises(Ardb::CLIRB::HelpExit){ cli.init }
    end

    should "raise an invalid command error when run" do
      assert_raises(InvalidCommandError){ subject.run }
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
      @adapter_spy = Class.new{ include Ardb::AdapterSpy }.new
      Assert.stub(Ardb::Adapter, Ardb.config.db.adapter.to_sym){ @adapter_spy }

      @ardb_init_called = false
      Assert.stub(Ardb, :init){ @ardb_init_called = true }

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

    should "parse its args when `init`" do
      subject.init
      assert_equal [], subject.clirb.args
    end

    should "initialize ardb and connect to the db via the adapter on run" do
      subject.run

      assert_true @ardb_init_called
      assert_true @adapter_spy.connect_db_called?

      exp = "connected to #{Ardb.config.db.adapter} db `#{Ardb.config.db.database}`\n"
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

      exp = "error connecting to #{Ardb.config.db.database.inspect} database " \
            "with #{Ardb.config.db_settings.inspect}"
      assert_includes exp, err_output
    end

  end

  class CreateCommandTests < UnitTests
    desc "CreateCommand"
    setup do
      @adapter_spy = Class.new{ include Ardb::AdapterSpy }.new
      Assert.stub(Ardb::Adapter, Ardb.config.db.adapter.to_sym){ @adapter_spy }

      @ardb_init_called_with = []
      Assert.stub(Ardb, :init){ |*args| @ardb_init_called_with = args }

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

    should "parse its args when `init`" do
      subject.init
      assert_equal [], subject.clirb.args
    end

    should "initialize ardb and create the db via the adapter on run" do
      subject.run

      assert_equal [false], @ardb_init_called_with
      assert_true @adapter_spy.create_db_called?

      exp = "created #{Ardb.config.db.adapter} db `#{Ardb.config.db.database}`\n"
      assert_equal exp, @stdout.read
    end

    should "output any errors and raise an exit error on run" do
      err = StandardError.new(Factory.string)
      Assert.stub(Ardb, :init){ raise err }

      assert_raises(CommandExitError){ subject.run }
      err_output = @stderr.read

      assert_includes err.to_s, err_output
      exp = "error creating #{Ardb.config.db.database.inspect} database"
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
    attr_reader :init_called, :run_called

    def initialize
      @init_called = false
      @run_called = false
    end

    def init
      @init_called = true
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

end
