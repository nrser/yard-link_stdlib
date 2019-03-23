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

#### Sub-Commands ####
require_relative './link_stdlib/add'
require_relative './link_stdlib/help'
require_relative './link_stdlib/list'
require_relative './link_stdlib/search'
require_relative './link_stdlib/url'


# Namespace
# =======================================================================

module  YARD
module  CLI


# Definitions
# =======================================================================

# Top-level {YARD::CLI::Command} for the `yard-link_stdlib` plugin. Added under 
# the name `stdlib` (see {YARD::LinkStdlib.install!}).
# 
# Simply a router to the sub-commands. Like {YARD::CLI::CommandParser}, which
# handles routing for `yard`, but is not really re-usable. In addition, this 
# class handles "-" → "_" conversion in sub-command names, since we have 
# multi-word commands.
# 
class LinkStdlib < Command
  
  @commands = SymbolHash[
    help: Help,
    list: List,
    add: Add,
    url: URL,
    search: Search,
  ]
  
  # Singleton Methods
  # ==========================================================================
  
  def self.commands
    @commands
  end
  
  
  # Instance Methods
  # ========================================================================

  def description
    "Mange Ruby stdlib linking"
  end
  

  def run *args
    # log.level = Logger::INFO
    
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

  
end # class LinkStdlib


# /Namespace
# =======================================================================

end # module CLI
end # module YARD
