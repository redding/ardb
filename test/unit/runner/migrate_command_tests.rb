require 'assert'
require 'ardb/runner/migrate_command'

class Ardb::Runner::MigrateCommand

  class BaseTests < Assert::Context
    desc "Ardb::Runner::MigrateCommand"
    setup do
      @cmd = Ardb::Runner::MigrateCommand.new
    end
    subject{ @cmd }

    should have_readers :migrations_path, :schema_file_path, :version, :verbose

    should "use the config's migrations and schema file paths" do
      assert_equal Ardb.config.migrations_path, subject.migrations_path
      assert_equal Ardb.config.schema_path, subject.schema_file_path
    end

    should "not target a specific version by default" do
      assert_nil subject.version
    end

    should "be verbose by default" do
      assert subject.verbose
    end

  end

  class VersionTests < BaseTests
    desc "with a version ENV setting"
    setup do
      ENV["VERSION"] = '12345'
      @cmd = Ardb::Runner::MigrateCommand.new
    end
    teardown do
      ENV["VERSION"] = nil
    end

    should "should target the given version" do
      assert_equal 12345, subject.version
    end

  end

  class VerboseTests < BaseTests
    desc "with a verbose ENV setting"
    setup do
      ENV["VERBOSE"] = 'no'
      @cmd = Ardb::Runner::MigrateCommand.new
    end
    teardown do
      ENV["VERBOSE"] = nil
    end

    should "turn off verbose mode if not set to 'true'" do
      assert_not subject.verbose
    end

  end

  # TODO: would be nice to have a system test that actually took some migrations
  # and ran them.

end
