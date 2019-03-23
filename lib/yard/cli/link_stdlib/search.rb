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

# Hooks into {YARD::LinkStdlib::ObjectMap#grep} to search for names using 
# regular expressions.
# 
class Search < Command
  
  include CommandHelper
  
  DESCRIPTION = "Find stdlib names that match Regexp patterns"
  USAGE = "yard stdlib search [OPTIONS] TERMS..."
  
  def run *args
    # Default format is `:plain`
    opts[ :format ] = :plain
    
    OptionParser.new { |op|
      add_header op, <<~END
        Examples:
        
          1.  {Pathname} instance methods
              
                  $ yard stdlib search '^Pathname#'
        
          2.  All `#to_s` methods
              
                  $ yard stdlib search '#to_s$'
          
          3.  Print results in serialized formats.
              
              All `#to_s` instance methods in JSON:
              
                  $ yard stdlib search --format=json '#to_s$'
              
              Supports a short `-f` flag and first-letter formats too.
              
              Instance methods of {Array} in YAML:
              
                  $ yard stdlib search -f y '^Array#'
      END
      
      add_version_opt op
      
      op.on(  '-u', '--urls',
              %(Print doc URLs along with names)
      ) { |urls| opts[ :urls ] = !!urls }
      
      op.on(  '-f FORMAT', '--format=FORMAT',
              %(Specify print format: (p)lain, (j)son or (y)aml)
      ) { |format|
        opts[ :format ] = \
          case format.downcase
          when 'p', 'plain'
            :plain
          when 'j', 'json'
            :json
          when 'y', 'yaml'
            :yaml
          else
            log.fatal \
              %(Unknown format - expected "plain", "json" or "yaml"; ) +
              %(given #{ format.inspect })
            exit false
          end
      }
      
    }.parse! args
    
    if args.empty?
      YARD::LinkStdlib::ObjectMap.
        current.
        names.
        sort_by( &:downcase ).
        each { |key| log.puts key }
      exit true
    end
    
    terms = args.map { |arg|
      begin
        Regexp.new arg
      rescue RegexpError => error
        Regexp.new \
          Regexp.escape( YARD::LinkStdlib.normalize_name( arg ) )
      end
    }
    
    log.debug "Terms:\n  " + terms.map( &:to_s ).join( "\n  " )
    
    names = YARD::LinkStdlib.grep *terms
    
    results = \
      if opts[ :urls ]
        names.each_with_object( {} ) { |name, hash|
          hash[ name ] = YARD::LinkStdlib::ObjectMap.current.url_for name
        }
      else
        names
      end
    
    case opts[ :format ]
    when :plain
      results.each do |entry|
        if entry.is_a? ::Array
          log.puts "#{ entry[0] } <#{ entry[ 1 ]}>"
        else
          log.puts entry
        end
      end
    when :json
      require 'json'
      log.puts JSON.pretty_generate( results )
    when :yaml
      require 'yaml'
      log.puts YAML.dump( results )
    end
    
    exit true
  end
end # class Search


# /Namespace
# =======================================================================

end # class  LinkStdlib
end # module CLI
end # module YARD
