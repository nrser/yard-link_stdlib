
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
  # spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
  #   `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  # end

  spec.files        = Dir[ "lib/**/*.rb" ] +
                      Dir[ "maps/*.json.gz" ] +
                      %w(bin/make_map.rb) +
                      %w(LICENSE.txt README.md NAME VERSION)

  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Dependencies
  # ============================================================================
  
  # Runtime Dependencies
  # ----------------------------------------------------------------------------

  spec.add_dependency "yard"
  
  
  # Development Dependencies
  # ----------------------------------------------------------------------------

  spec.add_development_dependency "bundler", ">= 1.16"
  spec.add_development_dependency "rake", "~> 12.3"
  spec.add_development_dependency "rspec", "~> 3.7"
  
  ### Pry - Nicer REPL experience & CLI-based debugging ###
  
  spec.add_development_dependency "pry", '~> 0.11.3'

  # Supposed to drop into pry as a debugger on unhandled exceptions, but I 
  # haven't gotten to test it yet
  spec.add_development_dependency "pry-rescue", '~> 1.4.5'

  # Move around the stack when you debug with `pry`, really sweet
  spec.add_development_dependency "pry-stack_explorer", '~> 0.4.9'
  
  
  ### YARD - Doc Generation ###

  # Provider for `commonmarker`, the new GFM lib
  spec.add_development_dependency 'yard-commonmarker', '~> 0.5.0'
  
  # My `yard clean` command
  spec.add_development_dependency 'yard-clean', '~> 0.1.0'
  
  
  ### Doctest - Exec-n-check YARD @example tags
  
  spec.add_development_dependency 'yard-doctest', '~> 0.1.16'

end
