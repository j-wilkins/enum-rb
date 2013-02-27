require 'redis/namespace'

class Renum

  def self.connection
    @connection
  end

  def self.connection=(arg)
    @connection = arg
  end

  def self.load_yaml(file)
    require 'yaml'
    load_hash(YAML.load_file(file))
  end

  def self.load_hash(hash)
    hash.each_pair do |key, value|
      Renum.new(key).set_value(value)
    end
  end

  attr_reader :name

  def initialize(name)
    @name = name
  end

  def value
    @value ||= get_value
  end

  def set_value(value)
    Setter.set_value(name, value)
  end

  def get_value
    Getter.get_value(@name)
  end

  private

  def connection
    self.class.connection
  end

  module Setter
    module_function

    def set_value(key, value)
      meth = :"set_#{value.class.to_s.downcase}_value"
      raise_cannot_store_value_type(value) unless self.respond_to?(meth)

      send(meth, key, value)
    end

    def set_string_value(key, value)
      connection.set(key, value)
    end

    def set_array_value(key, value)
      connection.multi do
        value.each_with_index do |v, index|
          (connection.rpush(key, v) && next) if v.is_a?(String)
          nested_value_key(key, index).tap do |nvkey|
            set_value(nvkey, v)
            connection.rpush(key, "ENUM_KEY:#{nvkey}")
          end
        end
      end
    end

    def set_hash_value(key, value)
      connection.multi do
        settable_hash = value.inject(Hash.new) do |out, pair|
          if pair.last.is_a?(String) || pair.last.is_a?(Fixnum)
            out[pair.first] = pair.last
          else
            nested_value_key(key, pair.first).tap do |nvkey|
              set_value(nvkey, pair.last)
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

    def connection
      Renum.connection
    end

    def namespace_name(name)
      return name if name[0..@name.length] == @name
      "#@name.#{name}"
    end

    def raise_cannot_store_value_type(value)
      raise "Renum cannot store values of class #{value.class}."
    end

  end

  module Getter
    module_function

    def get_value(key)
      meth = :"get_#{connection.type(key)}_value"

      raise_unknown_value_type(meth, key) unless self.respond_to?(meth)

      send(meth, key)
    end

    def get_string_value(key)
      connection.get(key)
    end

    def get_list_value(key)
      connection.lrange(key, 0, -1).map do |value|
        is_enum_key?(value) ? get_value(value[9..-1]) : value
      end
    end

    def get_hash_value(key)
      connection.hgetall(key).inject(Hash.new) do |out, pair|
        k, v = pair
        out[k] = is_enum_key?(v) ? get_value(v[9..-1]) : v
        out
      end
    end

    def is_enum_key?(key)
      !/ENUM_KEY:.*/.match(key.to_s).nil?
    end

    def connection
      Renum.connection
    end

    def raise_unknown_value_type(meth, key)
      raise "#{key} has unknown value type: #{meth} is not defined."
    end

  end

end
