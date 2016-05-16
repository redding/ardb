require 'ardb/adapter/base'

module Ardb::Adapter

  class Mysql < Base

    def foreign_key_add_sql
      "ALTER TABLE :from_table"\
      " ADD CONSTRAINT :name"\
      " FOREIGN KEY (:from_column)"\
      " REFERENCES :to_table (:to_column)"
    end

    def foreign_key_drop_sql
      "ALTER TABLE :from_table"\
      " DROP FOREIGN KEY :name"
    end

  end

end
