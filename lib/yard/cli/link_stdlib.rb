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
  
  
  class Path < Command
    def description
      "Print the online doc relative path for a stdlib name"
    end
    
    def run name
      path = YARD::LinkStdlib.path_for name
      
      if path.nil?
        $stderr.puts "Name not found: #{ name.inspect }"
        exit false
      end
      
      puts path
      exit true
    end
  end
  
  
  class URL < Command
    def description
      "Print the online doc URL for a stdlib name"
    end
    
    def run name
      url = YARD::LinkStdlib.url_for name
      
      if url.nil?
        $stderr.puts "Name not found: #{ name.inspect }"
        exit false
      end
      
      puts url
      exit true
    end
  end
  
  
  class Search < Command
    def description
      "Find stdlib names that match patterns"
    end
    
    def run *args
      opts = {
        regexp: false,
      }
      
      OptionParser.new { |op|
        op.banner = "Usage: yard stdlib search [OPTIONS] TERMS..."
        op.separator "" 
        op.separator description
        op.separator ""
        op.separator "Examples:"
        op.separator ""
        op.separator "  1.  {Pathname} instance methods"
        op.separator "      "
        op.separator "      yard stdlib search --regexp '^Pathname#'"
        op.separator ""
        op.separator "  2. All `#to_s` methods"
        op.separator "      "
        op.separator "      yard stdlib search --regexp '#to_s$'"
        op.separator ""
        op.separator "Options:"
        
        op.on( '-r', '--regexp', %(Parse TERMS as {Regexp}) ) do |regexp|
          opts[ :regexp ] = regexp
        end
        
        op.on_tail( '-h', '--help', %(You're looking at it!) ) {
          log.puts op
          exit true
        }
      }.parse! args
      
      if args.empty?
        YARD::LinkStdlib::ObjectMap.
          current.
          names.
          sort.
          each { |key| log.puts key }
        exit true
      end
      
      terms = if opts[ :regexp ]
        args.map { |arg| Regexp.new arg }
      else
        args
      end
      
      # log.puts terms.inspect
      
      names = YARD::LinkStdlib.grep *terms
      
      names.each { |name| log.puts name }
      exit true
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
      path: Path,
      url: URL,
      search: Search,
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
