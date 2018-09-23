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


# Namespace
# =======================================================================

module  YARD
module  CLI

# Definitions
# =======================================================================


# @todo document LinkStdlib class.
class LinkStdlib < Command
  
  # Instance Methods
  # ========================================================================

  def description
    "Mange Ruby stdlib linking"
  end
  

  def run *args
    puts "I'm here! Args: #{ args.inspect }"
  end
  
end # class LinkStdlib

# /Namespace
# =======================================================================

end # module CLI
end # module YARD
