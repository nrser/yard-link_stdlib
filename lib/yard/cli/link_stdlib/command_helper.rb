# encoding: UTF-8
# frozen_string_literal: true

# Requirements
# =======================================================================

### Deps ###

# We need {YARD::CLI::Command}
require 'yard'

### Project / Package ###

# `.make_missing`, `.set` from {YARD::LinkStdlib::RubySource}
require 'yard/link_stdlib/ruby_source'


# Namespace
# =======================================================================

module  YARD
module  CLI
class   LinkStdlib < Command


# Definitions
# =======================================================================

module CommandHelper
  
  def description
    self.class::DESCRIPTION
  end
  
  
  def usage
    self.class::USAGE
  end
  
  
  def check_args! args, count
    if args.length < count
      log.error "Too few args! Expected #{ count }, given #{ args.length }"
      exit false
    elsif args.length > count
      log.error "Too many args! Expected #{ count }, given #{ args.length }"
      exit false
    end
    
    if args.length == 1 then args[ 0 ] else args end
  end

  
  def opts
    @opts ||= {}
  end
  

  def add_header op, text = nil
    op.banner = description
    op.separator ''
    op.separator 'Usage:'
    op.separator ''
    op.separator "    #{ usage }"
    op.separator ''
    unless text.nil?
      text.lines.each { |line| op.separator line }
    end
    
    # Call {YARD::CLI::Command#common_options}, which adds file loading, plugin
    # loading, logging, YARD version and help options
    common_options( op )
  end
  
  def add_version_opt op
    # **DON'T** make missing versions by default here!
    YARD::LinkStdlib::RubySource.make_missing = false
    
    op.on(
      '-R VERSION',
      '--ruby-version=VERSION',
      %(Set Ruby version)
    ) { |ruby_version|
      YARD::LinkStdlib::RubyVersion.set ruby_version
    }
    
    op.on(
      '--make-missing',
      %(Download and make an object map if the Ruby version is not present)
    ) { |make_missing|
      YARD::LinkStdlib::RubySource.make_missing = make_missing
    }
  end
  
end # CommandHelper


# /Namespace
# =======================================================================

end # class  LinkStdlib
end # module CLI
end # module YARD
