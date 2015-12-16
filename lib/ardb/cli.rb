require 'ardb/version'
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

    InvalidCommandError = Class.new(ArgumentError)

  end

end
