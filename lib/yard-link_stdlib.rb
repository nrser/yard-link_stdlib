# encoding: UTF-8
# frozen_string_literal: true

# Requirements
# =======================================================================

# Deps
# -----------------------------------------------------------------------

require 'yard'

# Project / Package
# -----------------------------------------------------------------------

require_relative "./yard-link_stdlib/version"
require_relative "./yard-link_stdlib/html_helper"


# Namespace
# =======================================================================

module  YARD
module  LinkStdlib


# Definitions
# =======================================================================

# Constants
# ----------------------------------------------------------------------------

# Available helper modules by their format (as found in `options.format`).
# 
# We only cover `:html` for the moment, but may add more in the future.
# 
# @return [Hash<Symbol, Module>]
# 
HELPERS_BY_FORMAT = {
  html: HtmlHelper,
}.freeze


# The {Proc} that we add to {YARD::Templates::Template.extra_includes} on
# {.install!}. The proc accepts template options and responds with the helper
# module corresponding to the format (if any - right now we only handle 
# `:html`).
# 
# We want this to be a constant so we can tell if it's there and
# avoid ever double-adding it.
# 
# @return [Proc<YARD::Templates::TemplateOptions -> Module?>]
# 
HELPER_FOR_OPTIONS = proc { |options|
  HELPERS_BY_FORMAT[ options.format ]
}.freeze


# Add the {HELPER_FOR_OPTIONS} {Proc} to
# {YARD::Templates::Template.extra_includes} (if it's not there already).
# 
# @see https://www.rubydoc.info/gems/yard/YARD/Templates/Template#extra_includes-class_method
# 
# @return [Boolean]
#   `true` if the proc was added, `false` if it was already there (noop).
# 
def self.install!
  # NOTE  Due to YARD start-up order, this happens *before* log level is set,
  #       so the `--debug` CLI switch won't help see it... don't know a way to
  #       at the moment.
  log.debug "Installing `yard-link_stdlib` plugin..."

  if ::YARD::Templates::Template.extra_includes.include? HELPER_FOR_OPTIONS
    false
  else
    ::YARD::Templates::Template.extra_includes << HELPER_FOR_OPTIONS
    true
  end
end # .install!


# Installation
# ============================================================================
# 
# Ideally I'd like to have this happen as some sort of start-up hook so the lib
# can be loaded without triggering the install, but I'm not yet aware of any
# mechanism for it, so here and now it be:
# 

install!


# /Namespace
# =======================================================================

end # module LinkStdlib
end # module YARD
