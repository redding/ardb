# frozen_string_literal: true

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
      @file_path  = File.join(migrations_path, "#{@file_name}.rb")

      migration_version = ActiveRecord::Migration.current_version
      @source =
        "class #{@class_name} "\
        "< ActiveRecord::Migration[#{migration_version}]\n"\
        "  def change\n"\
        "  end\n"\
        "end\n"
    end

    def save!
      FileUtils.mkdir_p migrations_path
      File.open(file_path, "w"){ |f| f.write(source) }
      self
    end

    private

    def get_file_name(identifier)
      "#{Time.now.strftime("%Y%m%d%H%M%S")}_#{identifier.underscore}"
    end
  end
end
