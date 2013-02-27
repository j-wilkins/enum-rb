require 'test/unit'
require 'renum'

Renum.connection = Redis::Namespace.new(:test_enums, redis: Redis.new, db: 11)

class TestRenum < Test::Unit::TestCase
  def setup
    @enum = Renum.new(:test)
    Renum.connection.flushdb
  end

  def teardown
    Renum.connection.flushdb
  end

  def test_sets_string_values
    @enum.set_value('hat')

    assert_equal 'hat', Renum.connection.get('test')
  end

  def test_gets_string_values
    Renum.connection.set('test', 'hat')

    assert_equal 'hat', @enum.value
  end

  def test_sets_list_values
    arr = %w{1 2 3}
    @enum.set_value(arr)

    assert_equal 'list', Renum.connection.type('test')
    assert_equal arr, Renum.connection.lrange('test', 0, -1)
  end

  def test_sets_list_values_with_complex_entries
    arr = [['1','2'], {'3' => '4'}, '5']
    @enum.set_value(arr)

    assert_equal 'list', Renum.connection.type('test')
    assert_equal(
      ['ENUM_KEY:nested.value:test.0', 'ENUM_KEY:nested.value:test.1', '5'],
      Renum.connection.lrange('test', 0, -1))

    assert_equal 'list', Renum.connection.type('nested.value:test.0')
    assert_equal ['1', '2'], Renum.connection.lrange('nested.value:test.0', 0, -1)

    assert_equal 'hash', Renum.connection.type('nested.value:test.1')
    assert_equal({'3' => '4'}, Renum.connection.hgetall('nested.value:test.1'))
  end

  def test_gets_list_values
    %w{1 2 3}.each {|i| Renum.connection.rpush('test', i)}

    assert_equal %w{1 2 3}, @enum.value
  end

  def test_gets_list_values_with_complex_types
    %w{1 2}.each {|i| Renum.connection.rpush('nested.value:test.0', i)}
    Renum.connection.hmset('nested.value:test.1', '3', '4')
    %w{ENUM_KEY:nested.value:test.0 ENUM_KEY:nested.value:test.1 5}.each do |s|
      Renum.connection.rpush('test', s)
    end
    arr = [['1', '2'], {'3' => '4'}, '5']

    assert_equal arr, @enum.value
  end

  def test_sets_hash_values
    hsh = {'1' => '2', '3' => '4'}
    @enum.set_value(hsh)

    assert_equal 'hash', Renum.connection.type('test')
    assert_equal hsh, Renum.connection.hgetall('test')
  end

  def test_sets_hash_values_with_complex_types
    hsh = {'1' => ['2', '3'], '4' => {'5' => '6'}, '7' => '8'}
    @enum.set_value(hsh)

    assert_equal(
      {'1' => 'ENUM_KEY:nested.value:test.1',
       '4' => 'ENUM_KEY:nested.value:test.4', '7' => '8'},
      Renum.connection.hgetall('test'))

    assert_equal ['2', '3'],
      Renum.connection.lrange('nested.value:test.1', 0, -1)
    assert_equal({'5' => '6'},
                 Renum.connection.hgetall('nested.value:test.4'))
  end

  def test_gets_hash_values
    Renum.connection.hmset('test', '1', '2', '3', '4')

    assert_equal({'1' => '2', '3' => '4'}, @enum.value)
  end

  def test_gets_hash_values_with_complex_types
    %w{2 3}.each {|i| Renum.connection.rpush('nested.value:test.1', i)}
    Renum.connection.hmset('nested.value:test.4', '5', '6')
    Renum.connection.hmset('test', 1, 'ENUM_KEY:nested.value:test.1', 4,
               'ENUM_KEY:nested.value:test.4', 7, 8)

    hsh = {'1' => ['2', '3'], '4' => {'5' => '6'}, '7' => '8'}
    assert_equal hsh, @enum.value
  end
end
