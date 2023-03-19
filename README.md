# Simple Logic Step

I believe that some of developers faced a situation when you can't convince your **customer** | **project manager** | **team lead** | **teammates** to use any of existing business logic handler, as they think it:
- has no value for business
- is hard to integrate
- needs to be learned be developers
- is no guarantee that this gem will be well maintained in the future
- is developed by no name author

But you still want to make your controllers and models as thin as possible.
If such situation is familiar for you then this gem is for you.
This is a one file gem, just copy `Service` class from `lib/simple_logic_step.rb` to your project and specs for it from `spec/simple_logic_step/logic_step_spec.rb`.

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add simple_logic_step

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install simple_logic_step

Gemfile:

    gem 'simple_logic_step'

## Usage

1. Create class inherited from `SimpleLogicStep::Service` or the class name you chose during copying `Service` class to your project.

```ruby
class YourService < SimpleLogicStep::Service
    # ...
end
```

2. Define `#process` method with your business logic

```ruby
class YourService < SimpleLogicStep::Service
  def process
    # Put your logic here
  end
end
```

3. Call your service
```ruby
  YourService.call(params: { name: 'name' }) # => instance of YourService
  YourService.call(params: { name: 'name' }).success? # => true
  YourService.call(params: { name: 'name' }).failure? # => false
```

### Context

Params should be passed as kwargs to `.call` method, inside `#process` method you can access them via `ctx` method. `ctx` is a simple hash

```ruby
class YourService < SimpleLogicStep::Service
  def process
    ctx[:params] # => { name: 'name' }
  end
end
```

### How to fail_step

By default service will end execution as success, if you need to fail it call `fail_step` method

```ruby
# Method signature
# semantic - represents flag which can be used to handle failures differently
#            use it when failure? flag is not enough to handle service result
# message - specify error message
fail_step(semantic: nil, message: nil)
```

```ruby
class YourService < SimpleLogicStep::Service
  def process
    fail(semantic: :not_found, message: 'Record not found')
  end
end

service = YourService.call
service.failure? # => true
service.success? # => false
service.semantic # => :not_found
service.message # => 'Record not found'
```

### How to use "never nesting" approach
"Never nesting" approach - is the approach when you use guard clause to handle negative cases until you reach positive case.

```ruby
class YourService < SimpleLogicStep::Service
  CONFLICT = :conflict
  NOT_FOUND = :not_found
  BAD_REQUEST = :bad_request

  attr_reader :record

  def process
    if ctx[:flag] == 'bad_request'
      fail_step(semantic: BAD_REQUEST, message: 'Oops, bad request')
      return
    end

    if ctx[:flag] == 'not_found'
      fail_step(semantic: NOT_FOUND, message: 'Oops, not found')
      return
    end

    if ctx[:flag] == 'conflict'
      fail_step(semantic: CONFLICT, message: 'Oops, conflict')
      return
    end

    @record = { id: 1, name: 'john' }
  end
end

def handle_conflict(result)
  {
    status: 409,
    message: result.message
  }
end

def handle_not_found(result)
  {
    status: 404,
    message: result.message
  }
end

def handle_bad_request(result)
  {
    status: 400,
    message: result.message
  }
end

def handle_success(result)
  {
    status: 200,
    data: result.record
  }
end

def lets_imagine_it_is_controller_action
  service = YourService.call(flag: %w[success bad_request not_found conflict].sample)

  # Block will be executed only if service failed
  # #success? method works in the similar way, but only when service success
  service.failure? do |result|
    case result.semantic
    when YourService::CONFLICT
      # return will end method execution
      return handle_conflict(result)
    when YourService::NOT_FOUND
      # return will end method execution
      return handle_not_found(result)
    when YourService::BAD_REQUEST
      # return will end method execution
      return handle_bad_request(result)
    end
  end

  handle_success(service)
end

lets_imagine_it_is_controller_action  # => {:status=>200, :data=>{:id=>1, :name=>"john"}}
lets_imagine_it_is_controller_action # => {:status=>409, :message=>"Oops, conflict"}
lets_imagine_it_is_controller_action # => {:status=>400, :message=>"Oops, bad request"}
lets_imagine_it_is_controller_action  # => {:status=>404, :message=>"Oops, not found"}
```
More complex example [See it here](https://github.com/differencialx/simple_logic_step/blob/main/examples/controller.rb)

### Prepare method

If you need to make some preparation before `#process` call use `#prepare` method

```ruby
class YourService < SimpleLogicStep::Service
  attr_reader :result

  def prepare
    ctx[:name] = ctx[:name].capitalize
  end

  def process
    @result = "Hello #{ctx[:name]}"
  end
end

YourService.call(name: 'john').result # "Hello John"
```

You can also add modify [`#call` method  ](https://github.com/differencialx/simple_logic_step/blob/main/lib/simple_logic_step.rb#L23) and add post process method or whatever you need.



## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
