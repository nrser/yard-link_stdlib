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

class List < Command
  include CommandHelper
  
  DESCRIPTION = "List Ruby versions"
  USAGE = "yard stdlib list"

  def run *args
    OptionParser.new { |op|
      add_header op
    }.parse! args
    
    check_args! args, 0
    
    log.puts \
      YARD::LinkStdlib::ObjectMap.
        all.
        map { |om| om.version.to_s }.
        join( "\n" )
  end
end # class List


# /Namespace
# =======================================================================

end # class  LinkStdlib
end # module CLI
end # module YARD
