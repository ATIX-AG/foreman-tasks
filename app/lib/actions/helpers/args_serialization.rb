module Actions
  module Helpers
    module ArgsSerialization
      class Builder
        attr_reader :hash
        def initialize(*objects)
          @hash = {}.with_indifferent_access
          objects.each do |object|
            add_object(object)
          end
        end

        private

        def add_object(object)
          case object
          when ActiveRecord::Base
            unless object.respond_to?(:action_input_key)
              raise "Serialized model has to repond to :action_input_key method"
            end
            key   = object.action_input_key
            value = object_to_value(object)
            add(key, value)
          when Hash
            add_hash(object_to_value(object))
          else
            raise "don't know how to serialize #{object.inspect}"
          end
        end

        def object_to_value(object)
          case object
          when Array
            object.map { |item| object_to_value(item) }
          when Hash
            object.reduce({}) do |new_hash, (key, value)|
              new_hash.update(key => object_to_value(value))
            end
          when ActiveRecord::Base
            unless object.respond_to?(:to_action_input)
              raise "Serialized model has to repond to :to_action_input method"
            end
            object.to_action_input
          when String, Numeric, true, false, nil, Dynflow::ExecutionPlan::OutputReference
            object
          else
            object.to_s
          end
        end

        def add_hash(hash)
          hash.each do |key, value|
            add(key, value)
          end
        end

        def add(key, value)
          if hash.has_key?(key)
            raise "Conflict while serializing action args in key #{key}"
          end
          hash.update(key => value)
        end
      end

      def serialize_args(*objects)
        phase! Dynflow::Action::Plan
        Builder.new(*objects).hash
      end
    end
  end
end

