require 'active_support/core_ext/string/inflections'
require 'ardb/runner'

# Note: currently only postgresql adapter supported

class Ardb::Runner::GenerateCommand

  def initialize(args)
    @item = args.shift
    @args = args
  end

  def run
    begin
      self.send("#{@item}_cmd").run
    rescue Exception => e
      $stderr.puts e, *(e.backtrace)
      $stderr.puts "Couldn't generate #{@item}."
    end
  end

  def migration_cmd
    MigrationCommand.new(@args.first)
  end

  class MigrationCommand
    attr_reader :identifier, :class_name, :file_name, :template

    def initialize(identifier)
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
      file_path = File.join(Ardb.config.migrations_path, "#{@file_name}.rb")
      File.open(file_path, "w"){ |f| f.write(@template) }
    end
  end

end
