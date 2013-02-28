require 'redis/namespace'

class Enum
  class RedisStore

    attr_reader :connection

    def initialize(redis = nil)
      @connection = redis || Redis::Namespace.new(:enum, redis: Redis.new)
    end

    def get_value(key)
      Getter.get_value(connection, key)
    end

    def set_value(key, value)
      Setter.set_value(connection, key, value)
    end

    def load_yaml(file)
      require 'yaml'
      load_hash(YAML.load_file(file))
    end

    def load_hash(hash)
      hash.each_pair do |key, value|
        Setter.set_value(connection, key, value)
      end
    end

    module Setter

      module_function

      def set_value(connection, key, value)
        meth = :"set_#{value.class.to_s.downcase}_value"
        raise_cannot_store_value_type(value) unless self.respond_to?(meth)

        send(meth, connection, key, value)
      end

      def set_string_value(connection, key, value)
        connection.set(key, value)
      end

      def set_array_value(connection, key, value)
        connection.multi do
          value.each_with_index do |v, index|
            (connection.rpush(key, v) && next) if v.is_a?(String)
            nested_value_key(key, index).tap do |nvkey|
              set_value(connection, nvkey, v)
              connection.rpush(key, "ENUM_KEY:#{nvkey}")
            end
          end
        end
      end

      def set_hash_value(connection, key, value)
        connection.multi do
          settable_hash = value.inject(Hash.new) do |out, pair|
            if pair.last.is_a?(String) || pair.last.is_a?(Fixnum)
              out[pair.first] = pair.last
            else
              nested_value_key(key, pair.first).tap do |nvkey|
                set_value(connection, nvkey, pair.last)
                out[pair.first] = "ENUM_KEY:#{nvkey}"
              end
            end
            out
          end

          connection.hmset(key, *settable_hash.to_a.flatten)
        end
      end

      def nested_value_key(base, addy)
        "nested.value:#{base}.#{addy}"
      end

      def namespace_name(name)
        return name if name[0..@name.length] == @name
        "#@name.#{name}"
      end

      def raise_cannot_store_value_type(value)
        raise "Enum cannot store values of class #{value.class}."
      end

    end # => Setter

    module Getter

      module_function

      def get_value(connection, key)
        raise_unknown_key(key) unless connection.exists(key)

        meth = :"get_#{connection.type(key)}_value"

        raise_unknown_value_type(meth, key) unless self.respond_to?(meth)

        send(meth, connection, key)
      end

      def get_string_value(connection, key)
        connection.get(key)
      end

      def get_list_value(connection, key)
        connection.lrange(key, 0, -1).map do |value|
          is_enum_key?(value) ? get_value(connection, value[9..-1]) : value
        end
      end

      def get_hash_value(connection, key)
        connection.hgetall(key).inject(Hash.new) do |out, pair|
          k, v = pair
          out[k] = is_enum_key?(v) ? get_value(connection, v[9..-1]) : v
          out
        end
      end

      def is_enum_key?(key)
        !/ENUM_KEY:.*/.match(key.to_s).nil?
      end

      def raise_unknown_value_type(meth, key)
        raise "#{key} has unknown value type: #{meth} is not defined."
      end

      def raise_unknown_key(key)
        raise ArgumentError.new("Enum [ #{key} ] is not defined.")
      end

    end # => Getter

  end
end
