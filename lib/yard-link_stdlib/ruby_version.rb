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


# {.ruby_version} rounded-off to the minor version (patch set to `0`).
# 
# [docs.ruby-lang.org](https://docs.ruby-lang.org) only serves docs for major 
# and minor releases, not patches (`2.3.0`, `2.4.0`, `2.5.0`, etc.).
# 
# @example
#   YARD::LinkStdlib.ruby_version = '2.5.1'
#   YARD::LinkStdlib.ruby_minor_version #=> '2.5.0'
# 
# @return [String]
# 
def self.ruby_minor_version
  ruby_version.sub /\.\d+\z/, '.0'
end


# /Namespace
# ========================================================================

end # module LinkStdlib
end # module YARD
