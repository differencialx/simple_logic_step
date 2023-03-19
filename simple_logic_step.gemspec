# frozen_string_literal: true

require_relative 'lib/simple_logic_step/version'

Gem::Specification.new do |spec|
  spec.name = 'simple_logic_step'
  spec.version = SimpleLogicStep::VERSION
  spec.authors = ['Al Bal']
  spec.email = ['differencialx@gmail.com']

  spec.summary = 'Simple service object implementation'
  spec.description = <<~HEREDOC
    I believe that some of developers faced a situation when you can't convince your customer | project manager | team lead | teammates to use any of existing business logic handler, as they think it:
    - has no value for business
    - is hard to integrate
    - needs to be learned be developers
    - is no guarantee that this gem will be well maintained in the future
    - is developed by no name author

    But you still want to make your controllers and models as thin as possible.
    If such situation is familiar for you then this gem is for you.
    This is a one file gem, just copy `Service` class from `lib/simple_logic_step.rb` to your project and specs for it from `spec/simple_logic_step/logic_step_spec.rb`.
  HEREDOC
  spec.homepage = 'https://github.com/differencialx/simple_logic_step'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 2.6.0'

  spec.metadata['allowed_push_host'] = 'https://rubygems.org/'
  spec.metadata['rubygems_mfa_required'] = 'true'
  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/differencialx/simple_logic_step'
  spec.metadata['changelog_uri'] = 'https://github.com/differencialx/simple_logic_step/blob/main/CHANGELOG.md'

  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']
end
