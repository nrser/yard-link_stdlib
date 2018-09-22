# frozen_string_literal: true
# encoding: UTF-8

##############################################################################
# 
# Handle the version of Ruby to link against.
# 
##############################################################################

# Namespace
# ========================================================================

module  YARD
module  LinkStdlib


# Definitions
# ========================================================================

DEFAULT_RUBY_VERSION = '2.5.1'


def self.ruby_version= version
  @ruby_version = version
end


def self.ruby_version
  @ruby_version || DEFAULT_RUBY_VERSION
end


# /Namespace
# ========================================================================

end # module LinkStdlib
end # module YARD
