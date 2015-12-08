require 'much-plugin'

module Ardb

  module DefaultOrderBy
    include MuchPlugin

    DEFAULT_ATTRIBUTE  = :order_by
    DEFAULT_SCOPE_PROC = proc{ self.class.scoped }

    plugin_included do
      extend ClassMethods
      include InstanceMethods

      @ardb_default_order_by_config = {}

    end

    module ClassMethods

      def default_order_by(options = nil)
        options ||= {}

        @ardb_default_order_by_config.merge!({
          :attribute  => options[:attribute] || DEFAULT_ATTRIBUTE,
          :scope_proc => options[:scope]     || DEFAULT_SCOPE_PROC
        })

        before_validation :ardb_default_order_by, :on => :create
      end

      def ardb_default_order_by_config
        @ardb_default_order_by_config
      end

    end

    module InstanceMethods

      private

      def reset_order_by
        attr_name  = self.class.ardb_default_order_by_config[:attribute]
        scope_proc = self.class.ardb_default_order_by_config[:scope_proc]

        current_max = self.instance_eval(&scope_proc).maximum(attr_name) || 0
        self.send("#{attr_name}=", current_max + 1)
      end

      def ardb_default_order_by
        attr_name = self.class.ardb_default_order_by_config[:attribute]
        reset_order_by if self.send(attr_name).to_s.empty?
        true
      end

    end

  end
end
