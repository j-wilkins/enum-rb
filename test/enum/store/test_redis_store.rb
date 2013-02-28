require 'test/unit'
require 'enum'
require 'enum/store/redis_store'


class TestEnumStoreRedisStore < Test::Unit::TestCase
  def setup
    @store = Enum::RedisStore.new(
      Redis::Namespace.new(:test_enums, redis: Redis.new, db: 11))
    @store.connection.flushdb
  end

  def teardown
    @store.connection.flushdb
  end

  def test_sets_string_values
    @store.set_value('test', 'hat')

    assert_equal 'hat', @store.connection.get('test')
  end

  def test_gets_string_values
    @store.connection.set('test', 'hat')

    assert_equal 'hat', @store.get_value('test')
  end

  def test_sets_list_values
    arr = %w{1 2 3}
    @store.set_value('test', arr)

    assert_equal 'list', @store.connection.type('test')
    assert_equal arr, @store.connection.lrange('test', 0, -1)
  end

  def test_sets_list_values_with_complex_entries
    arr = [['1','2'], {'3' => '4'}, '5']
    @store.set_value('test', arr)

    assert_equal 'list', @store.connection.type('test')
    assert_equal(
      ['ENUM_KEY:nested.value:test.0', 'ENUM_KEY:nested.value:test.1', '5'],
      @store.connection.lrange('test', 0, -1))

    assert_equal 'list', @store.connection.type('nested.value:test.0')
    assert_equal ['1', '2'], @store.connection.lrange('nested.value:test.0', 0, -1)

    assert_equal 'hash', @store.connection.type('nested.value:test.1')
    assert_equal({'3' => '4'}, @store.connection.hgetall('nested.value:test.1'))
  end

  def test_gets_list_values
    %w{1 2 3}.each {|i| @store.connection.rpush('test', i)}

    assert_equal %w{1 2 3}, @store.get_value('test')
  end

  def test_gets_list_values_with_complex_types
    %w{1 2}.each {|i| @store.connection.rpush('nested.value:test.0', i)}
    @store.connection.hmset('nested.value:test.1', '3', '4')
    %w{ENUM_KEY:nested.value:test.0 ENUM_KEY:nested.value:test.1 5}.each do |s|
      @store.connection.rpush('test', s)
    end
    arr = [['1', '2'], {'3' => '4'}, '5']

    assert_equal arr, @store.get_value('test')
  end

  def test_sets_hash_values
    hsh = {'1' => '2', '3' => '4'}
    @store.set_value('test', hsh)

    assert_equal 'hash', @store.connection.type('test')
    assert_equal hsh, @store.connection.hgetall('test')
  end

  def test_sets_hash_values_with_complex_types
    hsh = {'1' => ['2', '3'], '4' => {'5' => '6'}, '7' => '8'}
    @store.set_value('test', hsh)

    assert_equal(
      {'1' => 'ENUM_KEY:nested.value:test.1',
       '4' => 'ENUM_KEY:nested.value:test.4', '7' => '8'},
      @store.connection.hgetall('test'))

    assert_equal ['2', '3'],
      @store.connection.lrange('nested.value:test.1', 0, -1)
    assert_equal({'5' => '6'},
                 @store.connection.hgetall('nested.value:test.4'))
  end

  def test_gets_hash_values
    @store.connection.hmset('test', '1', '2', '3', '4')

    assert_equal({'1' => '2', '3' => '4'}, @store.get_value('test'))
  end

  def test_gets_hash_values_with_complex_types
    %w{2 3}.each {|i| @store.connection.rpush('nested.value:test.1', i)}
    @store.connection.hmset('nested.value:test.4', '5', '6')
    @store.connection.hmset('test', 1, 'ENUM_KEY:nested.value:test.1', 4,
               'ENUM_KEY:nested.value:test.4', 7, 8)

    hsh = {'1' => ['2', '3'], '4' => {'5' => '6'}, '7' => '8'}
    assert_equal hsh, @store.get_value('test')
  end

  def test_raises_on_unset_values
    assert_raises ArgumentError do
      @store.get_value('unset.test')
    end
  end
end
