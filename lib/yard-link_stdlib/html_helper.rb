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
# @see https://www.rubydoc.info/gems/yard/YARD%2FTemplates%2FTemplate.extra_includes
# 
module HtmlHelper

  # The {Proc} we pass to 
  # 
  # @return [Proc]
  # 
  INCLUDE_FILTER = proc do |options|
    HtmlHelper if options.format == :html
  end


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
      
      version = LinkStdlib.ruby_minor_version
      
      [
        %{<a href="https://docs.ruby-lang.org/en/#{ version }/#{ path }">},
        key,
        %{</a>},
      ].join ''

    else
      LinkStdlib.dump "Got nada.",
        super_link: super_link
      
      super_link

    end

  end # #link_object

end # module HtmlHelper


# /Namespace
# ========================================================================

end # module LinkStdlib
end # module YARD
