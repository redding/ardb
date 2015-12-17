require 'fileutils'

module Ardb

  class Migration

    attr_reader :identifier, :class_name, :file_name, :file_path
    attr_reader :source

    def initialize(identifier)
      raise NoIdentifierError if identifier.to_s.empty?

      @identifier = identifier
      @class_name = @identifier.classify.pluralize
      @file_name  = get_file_name(@identifier)
      @file_path  = File.join(Ardb.config.migrations_path, "#{@file_name}.rb")

      @source = "require 'ardb/migration_helpers'\n\n" \
                "class #{@class_name} < ActiveRecord::Migration\n" \
                "  include Ardb::MigrationHelpers\n\n" \
                "  def change\n" \
                "  end\n\n" \
                "end\n"
    end

    def save!
      FileUtils.mkdir_p Ardb.config.migrations_path
      File.open(self.file_path, 'w'){ |f| f.write(self.source) }
      self
    end


    private

    def get_file_name(identifier)
      "#{Time.now.strftime("%Y%m%d%H%M%S")}_#{identifier.underscore}"
    end

    NoIdentifierError = Class.new(ArgumentError)

  end

end
