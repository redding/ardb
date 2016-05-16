require 'fileutils'
require 'ardb'
require 'ardb/adapter/base'

class Ardb::Adapter

  class Sqlite < Base

    def db_file_path
      File.expand_path(self.database, Ardb.config.root_path)
    end

    def validate!
      if File.exist?(self.db_file_path)
        raise RuntimeError, "`#{self.database}` already exists"
      end
    end

    def create_db
      validate!
      FileUtils.mkdir_p File.dirname(self.db_file_path)
      ActiveRecord::Base.establish_connection(self.ar_connect_hash)
    end

    def drop_db
      FileUtils.rm(self.db_file_path) if File.exist?(self.db_file_path)
    end

  end

end
