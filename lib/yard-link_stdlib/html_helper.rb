# frozen_string_literal: true
# encoding: UTF-8

# Requirements
# ========================================================================

# Stdlib
# ------------------------------------------------------------------------

require 'zlib'

# Deps
# ------------------------------------------------------------------------

require 'yard'

# Project / Package
# ------------------------------------------------------------------------

require_relative './dump'
require_relative './ruby_version'
require_relative './ruby_map'


# Namespace
# ========================================================================

module  YARD
module  LinkStdlib


# Definitions
# ========================================================================

# A helper module to add to {YARD::Templates::Template.extra_includes} to 
# handle linking stdlib references.
# 
# @see https://www.rubydoc.info/gems/yard/YARD/Templates/Template#extra_includes-class_method
# 
module HtmlHelper

  # The only real meat of this whole gem - hook into object linking.
  # 
  # We link to the stdlib if:
  # 
  # 1.  We didn't link to anything else (local stuff take precedence).
  # 2.  We can find a match for the reference.
  # 
  # @see https://www.rubydoc.info/gems/yard/YARD/Templates/Helpers/HtmlHelper#link_object-instance_method
  # 
  # @param [YARD::CodeObjects::Base] obj
  #   The object to link to.
  # 
  # @param [String?] title
  #   Optional title to display the link as.
  # 
  # @param [nil | ?] anchor
  #   Not sure... not doc'd in YARD.
  # 
  # @param [Boolean] relative
  #   Again, not sure... not doc'd in YARD, but seems like a boolean.
  # 
  # @return [String]
  #   The HTML source for the link.
  # 
  def link_object obj, title = nil, anchor = nil, relative = true
    # See what the super method can do...
    super_link = super

    # Bail out unless `super` returned a {String}, which I'm guessing would be
    # `nil`, but not sure.
    unless super_link.is_a?( String )
      LinkStdlib.dump "Object not linkable",
        obj: obj,
        super_link: super_link
      return super_link
    end

    LinkStdlib.dump "Object *may* be linkable!",
      obj: obj,
      super_link: super_link

    # `key` is what we gonna look up in the stdlib...
    key = super_link

    # Strip off any leading `::`
    key = key[2..-1] if key.start_with?( '::' )

    # Stdlib rdoc uses `ClassOrModule::class_method` format for class methods,
    # so we want to convert to that
    stdlib_key = key.sub /\.(\w+[\?\!]?)\z/, '::\1'

    if ( path = Map.get[ stdlib_key ] )
      LinkStdlib.dump "Matched stdlib link!",
        path: path,
        key: key,
        stdlib_key: stdlib_key
      
      ruby_version = LinkStdlib.ruby_version
      
      %{<a href="https://docs.ruby-lang.org/en/#{ ruby_version }/#{ path }">#{ key }</a>}

    else
      LinkStdlib.dump "Got nada.",
        super_link: super_link
      
      super_link

    end

  end # #link_object


  # The bound {Method} reference to this guy is what gets added to 
  # {YARD::Templates::Template.extra_includes}.
  # 
  # All it does it return `self` if the format is `:html`.
  # 
  # Normally, this would just be a lambda or such, but I made {#install!}
  # idempotent, so it looks for this method exactly when deciding if it needs
  # to be added.
  # 
  # @param [YARD::Templates::TemplateOptions] options
  #   The options for the template in question. I'm guessing re what class it
  #   is, but it seems like a reasonable guess. All we care is that is has a
  #   `#format` that can be `:html`.
  # 
  # @return [nil]
  #   If `options.format` *is not* `:html`.
  # 
  # @return [self]
  #   If `options.format` *is* `:html`.
  # 
  def self._installation_target options
    self if options.format == :html
  end


  # Module method to add the helper to
  # {YARD::Templates::Template.extra_includes} (if it's not there already).
  # 
  # What actually gets added is a bound reference to {._installation_target},
  # which simply returns `self` if the format is `:html` (we're not handling
  # anything else at this time).
  # 
  # @see https://www.rubydoc.info/gems/yard/YARD/Templates/Template#extra_includes-class_method
  # 
  # @return [Boolean]
  #   `true` if the helper was added, `false` if it was already there (noop).
  # 
  def self.install!
    target = self.method :_installation_target

    if ::YARD::Templates::Template.extra_includes.include? target
      false
    else
      ::YARD::Templates::Template.extra_includes << target
      true
    end
  end # .install!

end # module HtmlHelper


# Installation
# ============================================================================

HtmlHelper.install!


# /Namespace
# ========================================================================

end # module LinkStdlib
end # module YARD
