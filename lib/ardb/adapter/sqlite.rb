require 'pathname'
require 'fileutils'
require 'ardb'
require 'ardb/adapter/base'

class Ardb::Adapter

  class Sqlite < Base

    def db_file_path
      if (path = Pathname.new(self.database)).absolute?
        path.to_s
      else
        Ardb.config.root_path.join(path).to_s
      end
    end

    def validate!
      if File.exist?(self.db_file_path)
        raise Ardb::Runner::CmdError, "#{self.database} already exists"
      end
    end

    def create_db
      validate!
      FileUtils.mkdir_p File.dirname(self.db_file_path)
      ActiveRecord::Base.establish_connection(self.config_settings)
    end

    def drop_db
      FileUtils.rm(self.db_file_path) if File.exist?(self.db_file_path)
    end

  end

end
