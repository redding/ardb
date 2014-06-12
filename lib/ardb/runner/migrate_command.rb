require 'fileutils'
require 'active_record'
require 'ardb/runner'
require 'ardb/migration_helpers'

class Ardb::Runner::MigrateCommand

  attr_reader :migrations_path, :version, :verbose

  def initialize
    @adapter = Ardb::Adapter.send(Ardb.config.db.adapter)
    @migrations_path = Ardb.config.migrations_path
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
      $stderr.puts e
      $stderr.puts "error migrating #{Ardb.config.db.database.inspect} database"
      raise Ardb::Runner::CmdFail
    end
  end

  def migrate_the_db
    if defined?(ActiveRecord::Migration::CommandRecorder)
      ActiveRecord::Migration::CommandRecorder.class_eval do
        include Ardb::MigrationHelpers::RecorderMixin
      end
    end

    ActiveRecord::Migrator.migrations_path = @migrations_path
    ActiveRecord::Migration.verbose = @verbose
    ActiveRecord::Migrator.migrate(@migrations_path, @version) do |migration|
      ENV["SCOPE"].blank? || (ENV["SCOPE"] == migration.scope)
    end

    @adapter.dump_schema
  end

end
