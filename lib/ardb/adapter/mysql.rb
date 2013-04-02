require 'ardb'
require 'ardb/adapter/base'

class Ardb::Adapter

  class Mysql < Base

    def foreign_key_add_sql(data={})
      "ALTER TABLE :from_table"\
      " ADD CONSTRAINT :name"\
      " FOREIGN KEY (:from_column)"\
      " REFERENCES :to_table (:to_column)"
    end

    def foreign_key_drop_sql(data={})
      "ALTER TABLE :from_table"\
      " DROP FOREIGN KEY :name"
    end

  end

end
