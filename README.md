# Enum-rb

Enum-rb tries to be a flexible way to store arbitrary data that your
application needs to function but doesn't really fit anywhere and
has no defined structure.

The idea is to use it to store things like `key => value` mappings for
your `select` boxes, or any mappings for that matter. Anytime you need
to just have some bit of formless data, Enum should be able to hold it.

Have more of these mappings than it would be smart to store in-memory?
No worries, Enum-rb comes with a `RedisStore` that will store your
enums in Redis.

## Installation

Add this line to your application's Gemfile:

    gem 'enum-rb'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install enum-rb

## Usage

You can use Enum-rb in two ways. If having a single store is all you need,
you can set

     Enum.default_backend
  
     # to either a populated `MemoryStore`, which you can get with
     
     Enum.default_backend = Enum::MemoryStore.new({your: {'enum' => 'data'}})
     
     # or a configured `RedisStore`, which you can get with
     
     Enum.default_backend = Enum::RedisStore.new(configured_redis_namespace)
     
     # and then use
     
     Enum[:your]            # => {'enum' => 'data'}
     Enum.fetch(:your)      # => {'enum' => 'data'}
     
     # unknown Enums cause exceptions
     
     Enum[:nope]            # => ArgumentError

Or you can alternatively have multiple enum stores by creating an instance
of `Enum` and passing it the store to use.

     @enum = Enum.new(Enum::MemoryStore.new({a: 'small', amount: ['of', 'enums']}))
     
     @enum[:a]             # => 'small'
     @enum.fetch(:amount)  # => ['of', 'enums']
     
     # unknown Enums cause exceptions
     
     @enum.feth(:nope)     # => ArgumentError

If you are using the `RedisStore`, you can use `RedisStore#load_hash` or
`RedisStore#load_yaml` to load the store. In redis, you can't use symbols
as names, but the `RedisStore` will handle storing nested hashes or arrays.

For instance you could call:

     Enum::RedisStore.new(configured_redis).load_hash(
       {
         'select_options' => [
           {'name' => 'howdy', 'value' => 'hello'},
           {'name' => 'later', 'value' => 'bye'}
         ],
         'other_stuff' => {
           ['somehow', 'this', 'seems', 'important']
         },

         '2 + 2' => '5'
       }
     )

and the `RedisStore` will get all that saved so that

     Enum['select_options']
     # => [{'name' => 'howdy', 'value' => 'hello'}, {...}]

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
