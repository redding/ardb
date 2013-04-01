require 'assert'
require 'ardb/runner/drop_command'

class Ardb::Runner::DropCommand

  class BaseTests < Assert::Context
    desc "Ardb::Runner::DropCommand"
    setup do
      @cmd = Ardb::Runner::DropCommand.new
    end
    subject{ @cmd }

    should have_instance_methods :run, :postgresql_cmd

  end

  class PostgresqlTests < BaseTests
    desc "Ardb::Runner::DropCommand::PostgresqlCommand"
    setup do
      @cmd = Ardb::Runner::DropCommand::PostgresqlCommand.new
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
    desc "Ardb::Runner::DropCommand::SqliteCommand"
    setup do
      @cmd = Ardb::Runner::DropCommand::SqliteCommand.new
    end

    should have_readers :config_settings, :database, :db_path

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

  end

  # TODO: would be nice to have a system test that actually created a db

end
