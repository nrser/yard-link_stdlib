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

class URL < Command
  
  include CommandHelper
  
  DESCRIPTION = "Print the online doc URL for a stdlib name"
  USAGE = "yard stdlib url [OPTIONS] NAME"
  
  def run *args
    OptionParser.new { |op|
      add_header op
      add_version_opt op
    }.parse! args
    
    name = check_args! args, 1
    
    url = YARD::LinkStdlib::ObjectMap.current.url_for name
    
    if url.nil?
      $stderr.puts "Name not found: #{ name.inspect }"
      exit false
    end
    
    puts url
    exit true
  end
end


# /Namespace
# =======================================================================

end # class  LinkStdlib
end # module CLI
end # module YARD
