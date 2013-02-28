
class Enum

  class << self

    def default_backend
      @default_backend ||= begin
        require 'enum/store/memory_store'
        Enum::MemoryStore.new
      end
    end

    def default_backend=(arg)
      @default_backend = arg
    end

    def [](arg)
      default_backend.get_value(arg)
    end
    alias fetch []

  end

  attr_reader :name, :backend

  def initialize(backend = nil)
    @backend = backend || Enum.default_backend
  end

  def fetch(name)
    backend.get_value(name)
  end
  alias [] fetch

end
