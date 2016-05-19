require 'ardb/migration_helpers'

class CreatePgJsonMigrateTest < ActiveRecord::Migration
  include Ardb::MigrationHelpers

  def change
    create_table :pg_json_test_records do |t|
      t.json  :json_attribute
    end
    add_column :pg_json_test_records, :jsonb_attribute, :jsonb
  end

end
