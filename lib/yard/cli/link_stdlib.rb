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


class OptionParser < ::OptionParser
  def after_parse_block
    @after_parse_block ||= []
  end
  
  def after_parse &block
    after_parse_block << block
  end

  def parse! *args
    super( *args ).tap { after_parse_block.each &:call }
  end
end


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
    op.separator ''
    op.separator 'Options:'
    
    op.on_tail( '-q', '--quiet', 'Show no warnings.' ) {
      log.level = Logger::ERROR
    }
    
    op.on_tail( '--verbose', 'Show more information.') {
      log.level = Logger::INFO
    }
    
    op.on_tail( '--debug', 'Show debugging information.' ) {
      log.level = Logger::DEBUG
    }
    
    op.on_tail( '--backtrace', 'Show stack traces' ) {
      log.show_backtraces = true
    }
    
    op.on_tail( '-h', '--help', %(You're looking at it!) ) {
      log.puts op
      exit true
    }
  end
  
  def add_version_opt op
    # **DON'T** make missing versions by default here!
    YARD::LinkStdlib::RubySource.make_missing = false
    
    op.on(
      '-v VERSION',
      '--ruby-version=VERSION',
      %(Set Ruby version)
    ) { |ruby_version|
      YARD::LinkStdlib::RubyVersion.set ruby_version
      # opts[ :ruby_version ] = ruby_version
    }
    
    op.on(
      '--make-missing',
      %(Download and make an object map if the Ruby version is not present)
    ) { |make_missing|
      YARD::LinkStdlib::RubySource.make_missing = make_missing
      # opts[ :make_missing ] = make_missing
    }
  end
  
end # CommandHelper


# @todo document LinkStdlib class.
class LinkStdlib < Command

  # Sub-commands
  # ============================================================================

  class List < Command
    include CommandHelper
    
    DESCRIPTION = "List Ruby versions"
    USAGE = "yard stdlib list"

    def run *args
      
      
      log.puts \
        YARD::LinkStdlib::ObjectMap.
          all.
          map { |om| om.version.to_s }.
          join( "\n" )
    end
  end # class List


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
      
      version = check_args! args, 1
    
      log.info "Adding object map for Ruby #{ version }..."
      YARD::LinkStdlib::ObjectMap.add version, force: opts[ :force ]
      
      exit true
    end
    
  end # class Add
  
  
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
  
  
  # Hooks into {YARD::LinkStdlib::ObjectMap#grep} to search for names using 
  # regular expressions.
  # 
  class Search < Command
    
    include CommandHelper
    
    DESCRIPTION = "Find stdlib names that match Regexp patterns"
    USAGE = "yard stdlib search [OPTIONS] TERMS..."
    
    def run *args
      OptionParser.new { |op|
        add_header op, <<~END
          Examples:
          
            1.  {Pathname} instance methods
                
                yard stdlib search '^Pathname#'
          
            2. All `#to_s` methods
                
                yard stdlib search '#to_s$'
        END
        
        add_version_opt op
        
        op.on(  '-u', '--urls',
                %(Print doc URLs along with names)
        ) { |urls| opts[ :urls ] = urls }
        
      }.parse! args
      
      if args.empty?
        YARD::LinkStdlib::ObjectMap.
          current.
          names.
          sort_by( &:downcase ).
          each { |key| log.puts key }
        exit true
      end
      
      terms = args.map { |arg| Regexp.new arg }
      
      log.debug "Terms:\n  " + terms.map( &:to_s ).join( "\n  " )
      
      names = YARD::LinkStdlib.grep *terms
      
      names.each { |name|
        line = \
          if opts[ :urls ]
            "#{ name } <#{ YARD::LinkStdlib::ObjectMap.current.url_for name }>"
          else
            name
          end
        log.puts line
      }
      
      exit true
    end
  end # class Search


  class Help < Command
    
    include CommandHelper
    
    DESCRIPTION = "Show this message"

    def run
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
  
  
  # Singleton Methods
  # ==========================================================================
  
  def self.commands
    {
      help: Help,
      list: List,
      add: Add,
      url: URL,
      search: Search,
    }
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
