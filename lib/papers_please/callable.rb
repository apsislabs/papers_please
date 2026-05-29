# frozen_string_literal: true

module PapersPlease
  module Callable
    def self.call(callable, *args)
      if callable.lambda?
        arity = callable.arity
        callable.call(*((arity >= 0) ? args.take(arity) : args))
      else
        callable.call(*args)
      end
    end
  end
end
