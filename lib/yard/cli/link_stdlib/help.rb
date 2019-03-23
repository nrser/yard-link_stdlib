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

class Help < Command
    
    include CommandHelper
    
    USAGE = "yard stdlib help [OTHER_OPTIONS]"
    DESCRIPTION = "Show this message"

    def run *args
      OptionParser.new { |op|
        add_header op
      }.parse! args
      
      commands = LinkStdlib.commands
      log.puts <<~END
        yard-link_stdlib provides linking to online Ruby docs for standard 
        library code objects.
        
        Usage:
        
            yard stdlib COMMAND... [OPTIONS] [ARGS]
        
        Commands:
        
      END
      commands.keys.sort_by(&:to_s).each do |command_name|
        command_class = commands[command_name]
        next unless command_class < Command
        command = command_class.new
        log.puts "%-8s %s" % [command_name, command.description]
      end
      log.puts
    end
  end


# /Namespace
# =======================================================================

end # class  LinkStdlib
end # module CLI
end # module YARD
