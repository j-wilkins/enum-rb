require 'test/unit'
require 'enum'
require 'enum/store/memory_store'

class TestEnumStoreMemoryStore < Test::Unit::TestCase

  def setup
    @store = Enum::MemoryStore.new({'test' => 'foobar'})
  end

  def test_set_value
    @store.set_value('test', 'foobar')

    assert_equal 'foobar', @store.instance_variable_get(:@store)['test']
  end

  def test_get_value
    @store.instance_variable_set(:@store, {'test' => 'foobar'})

    assert_equal 'foobar', @store.get_value('test')
  end

  def test_raises_on_undefined_value
    assert_raises ArgumentError do
      @store.get_value(:test)
    end
  end

end
