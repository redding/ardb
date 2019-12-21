require "fileutils"

module Ardb
  class Migration
    NoIdentifierError = Class.new(ArgumentError)

    attr_reader :migrations_path, :identifier
    attr_reader :class_name, :file_name, :file_path, :source

    def initialize(ardb_config, identifier)
      raise NoIdentifierError if identifier.to_s.empty?

      @migrations_path = ardb_config.migrations_path
      @identifier      = identifier

      @class_name = @identifier.classify.pluralize
      @file_name  = get_file_name(@identifier)
      @file_path  = File.join(self.migrations_path, "#{@file_name}.rb")

      @source = "require \"ardb/migration_helpers\"\n\n" \
                "class #{@class_name} < ActiveRecord::Migration\n" \
                "  include Ardb::MigrationHelpers\n\n" \
                "  def change\n" \
                "  end\n" \
                "end\n"
    end

    def save!
      FileUtils.mkdir_p self.migrations_path
      File.open(self.file_path, "w"){ |f| f.write(self.source) }
      self
    end

    private

    def get_file_name(identifier)
      "#{Time.now.strftime("%Y%m%d%H%M%S")}_#{identifier.underscore}"
    end
  end
end
