require 'assert'
require 'ardb/adapter/postgresql'

class Ardb::Adapter::Postgresql

  class BaseTests < Assert::Context
    desc "Ardb::Adapter::Postgresql"
    setup do
      @adapter = Ardb::Adapter::Postgresql.new
    end
    subject { @adapter }

    should have_instance_method :public_schema_settings

    should "know it's public schema connection settings" do
      exp_settings = subject.config_settings.merge({
        :database => 'postgres',
        :schema_search_path => 'public'
      })
      assert_equal exp_settings, subject.public_schema_settings
    end

    should "know its foreign key add sql" do
      exp_add_sql = "ALTER TABLE :from_table"\
                    " ADD CONSTRAINT :name"\
                    " FOREIGN KEY (:from_column)"\
                    " REFERENCES :to_table (:to_column)"
      assert_equal exp_add_sql, subject.foreign_key_add_sql
    end

    should "know its foreign key drop sql" do
      exp_drop_sql = "ALTER TABLE :from_table"\
                     " DROP CONSTRAINT :name"
      assert_equal exp_drop_sql, subject.foreign_key_drop_sql
    end

  end

end
