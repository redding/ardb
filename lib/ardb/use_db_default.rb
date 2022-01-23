# frozen_string_literal: true

require "much-mixin"

module Ardb
  module UseDbDefault
    include MuchMixin

    mixin_included do
      @ardb_use_db_default_attrs = []

      around_create :ardb_allow_db_to_default_attrs
    end

    mixin_class_methods do
      def ardb_use_db_default_attrs
        @ardb_use_db_default_attrs
      end

      def use_db_default(*attrs)
        @ardb_use_db_default_attrs += attrs.map(&:to_s)
        @ardb_use_db_default_attrs.uniq!
      end
    end

    mixin_instance_methods do
      private

      def ardb_allow_db_to_default_attrs
        # this allows the attr to be defaulted by the DB, this keeps
        # activerecord from adding the attr into the sql `INSERT`, which will
        # make the DB default its value
        unchanged_names =
          self.class.ardb_use_db_default_attrs.reject do |name|
            send("#{name}_changed?")
          end
        unchanged_names.each{ |name| @attributes.delete(name) }
        yield
        # we have to go and fetch the attr value from the DB, otherwise
        # activerecord doesn"t know the value that the DB used
        scope = self.class.where(id: id)
        unchanged_names.each do |name|
          @attributes[name] = scope.pluck(name).first
        end
      end
    end
  end
end
