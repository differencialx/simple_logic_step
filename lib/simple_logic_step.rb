# frozen_string_literal: true

require_relative 'simple_logic_step/version'

module SimpleLogicStep
  # Copy from here
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
  # to here
end
