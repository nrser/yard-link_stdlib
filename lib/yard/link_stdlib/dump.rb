# frozen_string_literal: true
# encoding: UTF-8


# Namespace
# ========================================================================

module  YARD
module  LinkStdlib


# Definitions
# ========================================================================

# Dump a hash of values as a `debug`-level log message (`log` is a global
# function when you're hangin' in the YARD).
# 
# @example Dump values with a message
#   dump "There was a problem with the ", obj, "object!",
#     value_a: value_a,
#     value_b: value_b
# 
# @example Dump values without a message
#   dump value_a: value_a, value_b: value_b
# 
# @param [Array<String | Object>] message
#   Optional log message. Entries will be space-joined to form the message 
#   string: strings will be left as-is, and other objects will be
#   stringified by calling their `#inspect` method. See examples.
# 
# @param [Hash<Symbol, Object>] values
#   Map of names to values to dump.
# 
# @return
#   Whatever `log.debug` returns.
# 
def self.dump *message, **values

  max_name_length = values.
    keys.
    map { |name| name.to_s.length }.
    max

  values_str = values.
    map { |name, value|
      name_str = "%-#{ max_name_length + 2 }s" % "#{ name }:"

      "  #{ name_str } #{ value.inspect } (#{ value.class })"
    }.
    join( "\n" )
  
  message_str = message.
    map { |part|
      case part
      when String
        part
      else
        part.inspect
      end
    }.
    join( " " )
  
  log_str = "Values:\n\n#{ values_str }\n"
  log_str = "#{ message_str }\n\n#{ log_str }" unless message_str.empty?

  log.debug "yard-link_stdlib: #{ log_str }"
end # .dump


# /Namespace
# ========================================================================

end # module LinkStdlib
end # module YARD
