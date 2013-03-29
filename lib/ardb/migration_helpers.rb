require 'ardb'

module Ardb; end
module Ardb::MigrationHelpers

  def foreign_key(from_table, from_column, to_table, options={})
    fk = ForeignKey.new(from_table, from_column, to_table, options)
    execute(fk.add_sql)
  end

  def drop_foreign_key(*args)
    from_table, from_column = args[0..1]
    options = args.last.kind_of?(Hash) ? args.last : {}
    fk = ForeignKey.new(from_table, from_column, nil, options)
    execute(fk.drop_sql)
  end

  def remove_column_with_fk(table, column)
    drop_foreign_key(table, column)
    remove_column(table, column)
  end

  class ForeignKey
    attr_reader :from_table, :from_column, :to_table, :to_column, :name,
                :adapter

    def initialize(from_table, from_column, to_table, options=nil)
      options ||= {}
      @from_table  = from_table
      @from_column = from_column
      @to_table    = to_table
      @to_column   = (options[:to_column] || 'id')
      @name        = (options[:name] || "fk_#{@from_table}_#{@from_column}")
      @adapter     = Ardb.config.db.adapter
    end

    def add_sql
      self.send("#{self.adapter}_add_sql")
    end

    def drop_sql
      self.send("#{self.adapter}_drop_sql")
    end

    protected

    def postgresql_add_sql
      "ALTER TABLE #{self.from_table}"\
      " ADD CONSTRAINT #{self.name}"\
      " FOREIGN KEY (#{self.from_column})"\
      " REFERENCES #{self.to_table} (#{self.to_column})"
    end

    def postgresql_drop_sql
      "ALTER TABLE #{self.from_table}"\
      " DROP CONSTRAINT #{self.name}"
    end

    def mysql_add_sql
      "ALTER TABLE #{self.from_table}"\
      " ADD CONSTRAINT #{self.name}"\
      " FOREIGN KEY (#{self.from_column})"\
      " REFERENCES #{self.to_table} (#{self.to_column})"
    end
    alias :mysql2_add_sql :mysql_add_sql

    def mysql_drop_sql
      "ALTER TABLE #{self.from_table}"\
      " DROP FOREIGN KEY #{self.name}"
    end
    alias :mysql2_drop_sql :mysql_drop_sql

  end

  # This file will setup the AR migration command recorder for being able to change our
  # stuff, require it in an initializer

  module RecorderMixin

    def foreign_key(*args)
      record(:foreign_key, args)
    end

    protected

    def invert_foreign_key(args)
      [ :drop_foreign_key, args ]
    end

  end

end
