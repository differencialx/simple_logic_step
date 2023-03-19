# Copied base service class

class Service
  attr_reader :ctx, :semantic, :message

  def self.call(**ctx)
    new(**ctx).call
  end

  def initialize(**ctx)
    @success = true
    @semantic = nil
    @ctx = ctx
    @message = nil
  end

  def call
    prepare
    process
    self
  end

  # Implement business logic here
  def process
    raise 'Not implemented'
  end

  def failure?
    if block_given?
      yield(self) unless success
    else
      !success
    end
  end

  def success?
    if block_given?
      yield(self) if success
    else
      success
    end
  end

  private

  attr_reader :success

  # Redefine this method in case
  # if you need to do some preparations
  # before #process call
  def prepare; end

  def fail_step(semantic: nil, message: nil)
    @success = false
    add_semantic(semantic)
    @message = message
  end

  def pass_step(semantic: nil, message: nil)
    @success = true
    add_semantic(semantic)
    @message = message
  end

  def add_semantic(semantic)
    @semantic = semantic
  end
end

# Model

class SomeModel
  attr_accessor :id, :name, :description, :errors

  def initialize(name:, description:)
    @id = nil
    @name = name
    @description = description
    @errors = []
  end

  def valid?
    if @name == 'invalid_name'
      @errors << 'Name is invalid'
      return false
    end

    true
  end

  def save
    @id = 1

    true
  end

  def as_json
    {
      id: @id,
      name: @name,
      description: @description
    }
  end
end

# Validation service

class ValidateParams < Service
  attr_reader :model, :errors

  def process
    @model = SomeModel.new(**ctx[:params])

    return if @model.valid?

    @errors = @model.errors

    fail_step(semantic: 400)
  end
end

# Permission service

class CheckPermissions < Service
  attr_reader :errors

  def process
    return if ctx[:model].name != 'no_permissions'

    @errors = ['You do not have a permissions']

    fail_step(semantic: 403)
  end
end

class Create < Service
  CONFLICT = 409
  SERVER_ERROR = 'server_error'

  attr_reader :errors

  def process
    if ctx[:model].name == 'conflict'
      fail_step(semantic: CONFLICT, message: 'Conflict during creation, try again later')
      return
    end

    if ctx[:model].name == 'server_error'
      fail_step(semantic: SERVER_ERROR)
      return
    end

    ctx[:model].save
  end
end

class SomeModelsController
  # This is a pseudo controller

  def initialize(create_params:)
    @create_params = create_params
  end

  def create
    validator = ValidateParams.call(params: @create_params)

    validator.failure? do |result|
      return common_client_error_handler(result)
    end

    permission = CheckPermissions.call(model: validator.model)

    permission.failure? do |result|
      return common_client_error_handler(result)
    end

    creator = Create.call(model: validator.model)

    creator.failure? do |result|
      case result.semantic
      when Create::CONFLICT
        return common_client_error_handler(result)
      when Create::SERVER_ERROR
        return common_server_error_handler(result)
      end
    end

    { data: creator.ctx[:model].as_json, status: 201 }
  end

  private

  def common_client_error_handler(result)
    {
      errors: result.errors || [result.message],
      status: result.semantic
    }
  end

  def common_server_error_handler(result)
    puts ' ---> Report to error tracker'

    {
      errors: ['Oops, something went wrong'],
      status: 500
    }
  end
end

def assert_equal(actual, expected, message)
  if actual == expected
    p "PASSED: #{message}"
  else
    p "FAILED: #{message}"
  end
end

assert_equal(
  SomeModelsController.new(
    create_params: {
      name: 'invalid_name',
      description: 'Description'
    }
  ).create,
  {
    errors: ['Name is invalid'],
    status: 400
  },
  'When invalid'
)

assert_equal(
  SomeModelsController.new(
    create_params: {
      name: 'no_permissions',
      description: 'Description'
    }
  ).create,
  {
    errors: ['You do not have a permissions'],
    status: 403
  },
  'When forbidden'
)

assert_equal(
  SomeModelsController.new(
    create_params: {
      name: 'conflict',
      description: 'Description'
    }
  ).create,
  {
    errors: ['Conflict during creation, try again later'],
    status: 409
  },
  'When conflict'
)

assert_equal(
  SomeModelsController.new(
    create_params: {
      name: 'server_error',
      description: 'Description'
    }
  ).create,
  {
    errors: ['Oops, something went wrong'],
    status: 500
  },
  'When server error'
)

assert_equal(
  SomeModelsController.new(
    create_params: {
      name: 'success',
      description: 'Description'
    }
  ).create,
  {
    data: {
      id: 1,
      name: 'success',
      description: 'Description'
    },
    status: 201
  },
  'When success'
)
