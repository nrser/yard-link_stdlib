# encoding: UTF-8
# frozen_string_literal: true

# Requirements
# =======================================================================

### Stdlib ###

require 'optparse'

### Deps ###

# We need {YARD::CLI::Command}
require 'yard'

### Project / Package ###

require_relative './command_helper'


# Namespace
# =======================================================================

module  YARD
module  CLI
class   LinkStdlib < Command


# Definitions
# =======================================================================

class Add < Command
  
  include CommandHelper
  
  DESCRIPTION = "Download version source and build object map"
  USAGE = "yard stdlib add [OPTIONS] RUBY_VERSION"

  def run *args
    # Want to see what's going on by default here...
    log.level = Logger::INFO
    
    opts[ :force ] = false
  
    OptionParser.new { |op|
      add_header op
      
      op.on( '-f', '--force',
              %(Force building of map data when already present)
      ) { |force| opts[ :force ] = force }
      
    }.parse! args
    
    args.each do |version|    
      log.info "Adding object map for Ruby #{ version }..."
      YARD::LinkStdlib::ObjectMap.add version, force: opts[ :force ]
    end
    
    exit true
  end
  
end # class Add


# /Namespace
# =======================================================================

end # class  LinkStdlib
end # module CLI
end # module YARD
