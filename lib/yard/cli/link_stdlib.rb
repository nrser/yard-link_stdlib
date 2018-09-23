# encoding: UTF-8
# frozen_string_literal: true

# Requirements
# =======================================================================

# Stdlib
# -----------------------------------------------------------------------

# Deps
# -----------------------------------------------------------------------

# We need {YARD::CLI::Command}
require 'yard'

# Project / Package
# -----------------------------------------------------------------------

require 'yard/link_stdlib/ruby_source'


# Namespace
# =======================================================================

module  YARD
module  CLI


# Definitions
# =======================================================================

# @todo document LinkStdlib class.
class LinkStdlib < Command

  # Subcommands
  # ============================================================================

  class List < Command
    def description
      "List Ruby versions"
    end

    def run
      log.puts \
        YARD::LinkStdlib::ObjectMap.
          list.
          map { |om| om.version.to_s }.
          join( "\n" )
    end
  end


  class Add < Command
    def description
      "Download version source and build object map"
    end

    def run version
      log.puts "Adding object map for Ruby #{ version }..."
      YARD::LinkStdlib::ObjectMap.new( version ).make
    end
  end


  class Help < Command
    def description
      "Show this message"
    end

    def run
      commands = LinkStdlib.commands
      log.puts "Usage: yard stdlib COMMAND... [OPTIONS] [ARGS]"
      log.puts
      log.puts "Commands:"
      commands.keys.sort_by(&:to_s).each do |command_name|
        command_class = commands[command_name]
        next unless command_class < Command
        command = command_class.new
        log.puts "%-8s %s" % [command_name, command.description]
      end
    end
  end

  
  # Instance Methods
  # ========================================================================

  def description
    "Mange Ruby stdlib linking"
  end


  def self.commands
    {
      help: Help,
      list: List,
      add: Add,
    }
  end
  

  def run *args
    target = self.class.commands

    args = [ 'help' ] if args.empty?

    while target.is_a? Hash
      key = args[0].gsub( '-', '_' ).to_sym
      if target.key? key
        target = target[key]
        args.shift
      else
        raise "Bad command name: #{ args[0] }"
      end
    end

    target.run( *args )
  end

  
  protected
  # ========================================================================
    
    # @todo Document respond method.
    # 
    # @param [type] arg_name
    #   @todo Add name param description.
    # 
    # @return [return_type]
    #   @todo Document return value.
    # 
    def respond response
      log.puts response unless response.nil?
      exit true
    end # #respond

  public # end protected ***************************************************

  
end # class LinkStdlib


# /Namespace
# =======================================================================

end # module CLI
end # module YARD
