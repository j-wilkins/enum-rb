
class Enum
  class MemoryStore

    def initialize(store = nil)
      @store = store || Hash.new
    end

    def get_value(key)
      @store.fetch(key) rescue fail_fetch(key)
    end

    def set_value(name, value)
      @store[name] = value
    end

    private

    def fail_fetch(key)
      raise ArgumentError.new("#{key} is not defined.")
    end
  end # => MemoryStore
end # => Enum
