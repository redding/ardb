require "assert"
require "ardb/migration"

# This is needed to call `classify` on a string; if this isn"t manually required
# these tests can fail if activesupport hasn"t been loaded by activerecord; the
# `Migration` class will error saying `classify` is not a method on `String`
require "active_support/core_ext/string/inflections"

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

      @ardb_config = Factory.ardb_config
      @id          = Factory.migration_id
      @migration   = @migration_class.new(@ardb_config, @id)
    end
    subject{ @migration }

    should have_readers  :migrations_path, :identifier
    should have_readers :class_name, :file_name, :file_path, :source
    should have_imeths :save!

    should "know its attrs" do
      assert_equal @ardb_config.migrations_path, subject.migrations_path
      assert_equal @id, subject.identifier

      exp = @id.classify.pluralize
      assert_equal exp, subject.class_name

      exp = "#{@time_now.strftime("%Y%m%d%H%M%S")}_#{@id.underscore}"
      assert_equal exp, subject.file_name

      exp = File.join(subject.migrations_path, "#{subject.file_name}.rb")
      assert_equal exp, subject.file_path

      exp = "require \"ardb/migration_helpers\"\n\n" \
            "class #{subject.class_name} < ActiveRecord::Migration\n" \
            "  include Ardb::MigrationHelpers\n\n" \
            "  def change\n" \
            "  end\n" \
            "end\n"
      assert_equal exp, subject.source
    end

    should "complain if no identifier is provided" do
      assert_raises(NoIdentifierError) do
        @migration_class.new(@ardb_config, [nil, ""].sample)
      end
    end

    should "write the migration source to the migrations path on save" do
      subject.save!

      assert_equal [subject.migrations_path], @mkdir_called_with
      assert_equal [subject.file_path, "w"],  @file_open_called_with
      assert_equal [subject.source],          @file_spy.write_called_with
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
