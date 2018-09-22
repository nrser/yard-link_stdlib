# Turn on Ruby's terribly funky "debug mode", which causes a whole shit-storm
# of largely useless screaming to spew all over your stdout...
# 
# https://stackoverflow.com/questions/15290672/debug-global-variable-in-ruby
# https://mislav.net/2011/06/ruby-verbose-mode/
# 
# *but*, it's also apparently how {YARD} decides to print plugin failure
# backtraces:
# 
# https://git.io/fAdK8
# 
# I'm not sure how to toggle `$DEBUG` on through the `yard` CLI, but I've been
# able to do it by loading this file like:
# 
#     yard doc --load dev/set_DEBUG.rb --debug --backtrace
# 

$DEBUG = true
