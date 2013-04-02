require 'ardb'
require 'ardb/adapter/base'

class Ardb::Adapter

  class Postgresql < Base

    def public_schema_settings
      self.config_settings.merge({
        :database           => 'postgres',
        :schema_search_path => 'public'
      })
    end

    def create_db
      ActiveRecord::Base.establish_connection(self.public_schema_settings)
      ActiveRecord::Base.connection.create_database(self.database, self.config_settings)
      ActiveRecord::Base.establish_connection(self.config_settings)
    end

    def drop_db
      ActiveRecord::Base.establish_connection(self.public_schema_settings)
      ActiveRecord::Base.connection.drop_database(self.database)
    end

    def foreign_key_add_sql
      "ALTER TABLE :from_table"\
      " ADD CONSTRAINT :name"\
      " FOREIGN KEY (:from_column)"\
      " REFERENCES :to_table (:to_column)"
    end

    def foreign_key_drop_sql
      "ALTER TABLE :from_table"\
      " DROP CONSTRAINT :name"
    end

  end

end
