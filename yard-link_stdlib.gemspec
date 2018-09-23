
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "yard/link_stdlib/version"

Gem::Specification.new do |spec|
  spec.name          = YARD::LinkStdlib::NAME
  spec.version       = YARD::LinkStdlib::VERSION
  spec.authors       = ["nrser"]
  spec.email         = ["neil@neilsouza.com"]

  spec.summary       = %q{A YARD plugin & patch to link Ruby stdlib references.}
  spec.description   = <<~END
    A YARD plugin (with a bit of monkey-business) to support referencing 
    modules, classes, methods, etc. from Ruby's standard library the same way
    you can reference things in your own code, like {String}.

    I find this makes the generated documentation considerably more useful and
    natural.
  END
  spec.homepage      = "https://github.com/nrser/yard-link_stdlib"
  spec.license       = "BSD"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "pry", "~> 0.11.3"

  spec.add_dependency "yard"
end
