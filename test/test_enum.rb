require 'test/unit'
require 'enum'

class TestEnum < Test::Unit::TestCase

  def setup
    @enum = Enum.new()
  end

  def test_class_fetch
    Enum.default_backend = Enum::MemoryStore.new({test: 'ahoy!'})

    assert_equal 'ahoy!', Enum.fetch(:test)
    assert_equal 'ahoy!', Enum[:test]
  end

  def test_initializes_with_defaults
    assert_equal Enum.default_backend, @enum.instance_variable_get(:@backend)
  end

  def test_value_calls_backend
    @enum.instance_variable_get(:@backend).set_value(:test, 'foobar')

    assert_equal 'foobar', @enum.fetch(:test)
    assert_equal 'foobar', @enum[:test]
  end

end
