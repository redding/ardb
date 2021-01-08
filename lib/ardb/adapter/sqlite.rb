# frozen_string_literal: true

require "fileutils"
require "ardb"
require "ardb/adapter/base"

module Ardb::Adapter
  class Sqlite < Ardb::Adapter::Base
    def db_file_path
      File.expand_path(database, config.root_path)
    end

    def validate!
      raise "`#{database}` already exists" if File.exist?(db_file_path)
    end

    def create_db
      validate!
      FileUtils.mkdir_p File.dirname(db_file_path)
      ActiveRecord::Base.establish_connection(connect_hash)
    end

    def drop_db
      FileUtils.rm(db_file_path) if File.exist?(db_file_path)
    end
  end
end
