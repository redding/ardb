require 'assert'
require 'ardb/runner/generate_command'

class Ardb::Runner::GenerateCommand

  class BaseTests < Assert::Context
    desc "Ardb::Runner::GenerateCommand"
    setup do
      @cmd = Ardb::Runner::GenerateCommand.new(['something'])
    end
    subject{ @cmd }

    should have_instance_methods :run, :migration_cmd

  end

  class MigrationTests < BaseTests
    desc "Ardb::Runner::GenerateCommand::MigrationCommand"
    setup do
      @cmd = Ardb::Runner::GenerateCommand::MigrationCommand.new('a_migration')
    end

    should have_readers :identifier, :class_name, :file_name, :template

    should "know its given identifier" do
      assert_equal 'a_migration', subject.identifier
    end

    should "know its class name" do
      assert_equal "AMigrations", subject.class_name
    end

    should "know its file name" do
      assert_match /.+_a_migration$/, subject.file_name
    end

    should "know its template" do
      assert_includes "require 'ardb/migration_helpers'", subject.template
      assert_includes "class #{subject.class_name} < ActiveRecord::Migration", subject.template
      assert_includes "include Ardb::MigrationHelpers", subject.template
      assert_includes "def change", subject.template
    end

  end

end
