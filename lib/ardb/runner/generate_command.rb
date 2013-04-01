require 'fileutils'
require 'active_support/core_ext/string/inflections'
require 'ardb/runner'

# Note: currently only postgresql adapter supported

class Ardb::Runner::GenerateCommand

  def initialize(args)
    @item = args.shift
    @args = args
  end

  def run
    if @item.nil?
      raise Ardb::Runner::CmdError, "specify an item to generate"
    end
    if !self.respond_to?("#{@item}_cmd")
      raise Ardb::Runner::CmdError, "can't generate #{@item}"
    end

    begin
      self.send("#{@item}_cmd")
    rescue Ardb::Runner::CmdError => e
      raise e
    rescue Exception => e
      $stderr.puts e, *(e.backtrace)
      $stderr.puts "error generating #{@item}."
    end
  end

  def migration_cmd
    MigrationCommand.new(@args.first).run
  end

  class MigrationCommand
    attr_reader :identifier, :class_name, :file_name, :template

    def initialize(identifier)
      if identifier.nil?
        raise Ardb::Runner::CmdError, "specify a name for the migration"
      end

      @identifier = identifier
      @class_name = @identifier.classify.pluralize
      @file_name  = begin
        "#{Time.now.strftime("%Y%m%d%H%M%S")}_#{@identifier.underscore}"
      end
      @template = "class #{@class_name} < ActiveRecord::Migration\n"\
                  "  def change\n"\
                  "  end\n"\
                  "end\n"
    end

    def run
      FileUtils.mkdir_p Ardb.config.migrations_path
      file_path = File.join(Ardb.config.migrations_path, "#{@file_name}.rb")
      File.open(file_path, "w"){ |f| f.write(@template) }
      $stdout.puts file_path
    end
  end

end
