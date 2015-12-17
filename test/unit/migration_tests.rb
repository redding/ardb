require "assert"
require "ardb/migration"

class Ardb::Migration

  class UnitTests < Assert::Context
    desc "Ardb::Migration"
    setup do
      @migration_class = Ardb::Migration
    end

  end

  class InitTests < UnitTests
    desc "when init"
    setup do
      @time_now = Time.now
      Assert.stub(Time, :now){ @time_now }

      @mkdir_called_with = []
      Assert.stub(FileUtils, :mkdir_p){ |*args| @mkdir_called_with = args }

      @file_spy = FileSpy.new
      @file_open_called_with = []
      Assert.stub(File, :open) do |*args, &block|
        @file_open_called_with = args
        block.call(@file_spy)
      end

      @id = Factory.migration_id
      @migration = @migration_class.new(@id)
    end
    subject{ @migration }

    should have_readers :identifier, :class_name, :file_name, :file_path
    should have_readers :source
    should have_imeths :save!

    should "know its attrs" do
      assert_equal @id, subject.identifier

      exp = @id.classify.pluralize
      assert_equal exp, subject.class_name

      exp = "#{@time_now.strftime("%Y%m%d%H%M%S")}_#{@id.underscore}"
      assert_equal exp, subject.file_name

      exp = File.join(Ardb.config.migrations_path, "#{subject.file_name}.rb")
      assert_equal exp, subject.file_path

      exp = "require 'ardb/migration_helpers'\n\n" \
            "class #{subject.class_name} < ActiveRecord::Migration\n" \
            "  include Ardb::MigrationHelpers\n\n" \
            "  def change\n" \
            "  end\n\n" \
            "end\n"
      assert_equal exp, subject.source
    end

    should "complain if no identifier is provided" do
      assert_raises(NoIdentifierError) do
        @migration_class.new([nil, ''].choice)
      end
    end

    should "write the migration source to the migrations path on save" do
      subject.save!

      assert_equal [Ardb.config.migrations_path], @mkdir_called_with
      assert_equal [subject.file_path, 'w'],      @file_open_called_with
      assert_equal [subject.source],              @file_spy.write_called_with
    end

  end

  class FileSpy
    attr_reader :write_called_with

    def initialize
      @write_called_with = nil
    end

    def write(*args)
      @write_called_with = args
    end
  end

end
