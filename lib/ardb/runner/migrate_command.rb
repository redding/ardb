require 'fileutils'
require 'active_record'
require 'ardb/runner'
require 'ardb/migration_helpers'

class Ardb::Runner::MigrateCommand

  attr_reader :migrations_path, :schema_file_path, :version, :verbose

  def initialize
    @migrations_path = Ardb.config.migrations_path
    @schema_file_path = Ardb.config.schema_path
    @version = ENV["VERSION"] ? ENV["VERSION"].to_i : nil
    @verbose = ENV["VERBOSE"] ? ENV["VERBOSE"] == "true" : true
  end

  def run
    begin
      Ardb.init
      migrate_the_db
    rescue Ardb::Runner::CmdError => e
      raise e
    rescue Exception => e
      $stderr.puts e, *(e.backtrace)
      $stderr.puts "error migrating #{Ardb.config.db.database.inspect} database"
      raise Ardb::Runner::CmdFail
    end
  end

  def migrate_the_db
    if defined?(ActiveRecord::Migration::CommandRecorder)
      ActiveRecord::Migration::CommandRecorder.send(:include, Ardb::MigrationHelpers::RecorderMixin)
    end

    ActiveRecord::Migrator.migrations_path = @migrations_path
    ActiveRecord::Migration.verbose = @verbose
    ActiveRecord::Migrator.migrate(@migrations_path, @version) do |migration|
      ENV["SCOPE"].blank? || (ENV["SCOPE"] == migration.scope)
    end

    require 'active_record/schema_dumper'
    FileUtils.mkdir_p File.dirname(@schema_file_path)
    File.open(@schema_file_path, "w:utf-8") do |file|
      ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection, file)
    end
  end

end
