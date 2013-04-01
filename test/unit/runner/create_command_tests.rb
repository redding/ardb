require 'assert'
require 'fileutils'
require 'ardb/runner/create_command'

class Ardb::Runner::CreateCommand

  class BaseTests < Assert::Context
    desc "Ardb::Runner::CreateCommand"
    setup do
      @cmd = Ardb::Runner::CreateCommand.new
    end
    subject{ @cmd }

    should have_instance_methods :run, :postgresql_cmd, :sqlite3_cmd

  end

  class PostgresqlTests < BaseTests
    desc "Ardb::Runner::CreateCommand::PostgresqlCommand"
    setup do
      @cmd = Ardb::Runner::CreateCommand::PostgresqlCommand.new
    end

    should have_readers :config_settings, :database

    should "use the config's db settings " do
      assert_equal Ardb.config.db.to_hash, subject.config_settings
    end

    should "use the config's database" do
      assert_equal Ardb.config.db.database, subject.database
    end

  end

  class SqliteTests < BaseTests
    desc "Ardb::Runner::CreateCommand::SqliteCommand"
    setup do
      @cmd = Ardb::Runner::CreateCommand::SqliteCommand.new
    end

    should have_readers :config_settings, :database, :db_path
    should have_instance_method :validate!

    should "use the config's db settings " do
      assert_equal Ardb.config.db.to_hash, subject.config_settings
    end

    should "use the config's database" do
      assert_equal Ardb.config.db.database, subject.database
    end

    should "know the full path to the db file" do
      exp_path = Ardb.config.root_path.join(Ardb.config.db.database).to_s
      assert_equal exp_path, subject.db_path
    end

    should "complain if the db file already exists" do
      FileUtils.mkdir_p(File.dirname(subject.db_path))
      FileUtils.touch(subject.db_path)
      assert_raises(Ardb::Runner::CmdError) { subject.validate! }
      FileUtils.rm(subject.db_path)
    end

  end

  # TODO: would be nice to have a system test that actually created a db

end
