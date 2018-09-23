# encoding: UTF-8
# frozen_string_literal: true

# Requirements
# =======================================================================

# Stdlib
# -----------------------------------------------------------------------

# Deps
# -----------------------------------------------------------------------

# Project / Package
# -----------------------------------------------------------------------

require_relative "./cli/link_stdlib"
require_relative "./link_stdlib/version"
require_relative "./link_stdlib/html_helper"


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
# @return [nil]
# 
def self.install!
  # NOTE  Due to YARD start-up order, this happens *before* log level is set,
  #       so the `--debug` CLI switch won't help see it... don't know a way to
  #       at the moment.
  log.debug "Installing `yard-link_stdlib` plugin..."

  unless YARD::Templates::Template.extra_includes.include? HELPER_FOR_OPTIONS
    YARD::Templates::Template.extra_includes << HELPER_FOR_OPTIONS
  end

  YARD::CLI::CommandParser.commands[:link_stdlib] ||= YARD::CLI::LinkStdlib

  nil
end # .install!


# General Utilities
# ----------------------------------------------------------------------------

# @param [Symbol | #to_s] value
#   Either an object whose string representation expands to a path to an
#   existing directory, or one of the following symbols:
#   
#   1.  `:system`, `:global` - `/tmp/yard-link_stdlib`
#   2.  
# 
# @return [Pathname]
#   The assigned path.
# 
def self.tmp_dir= value
  @tmp_dir = case value
  when :system, :global
    Pathname.new '/tmp/yard-link_stdlib'
  when :user
    Pathname.new( '~/tmp/yard-link_stdlib' ).expand_path
  when :gem, :install
    ROOT.join 'tmp'
  when :project
    Pathname.getwd.join 'tmp', 'yard-link_stdlib'
  else
    dir = Pathname.new( value.to_s ).expand_path

    unless dir.directory?
      raise ArgumentError,
        "When assigning a custom tmp_dir path it must be an existing " +
        "directory, received #{ value.to_s.inspect }"
    end
  end

  FileUtils.mkdir_p @tmp_dir unless @tmp_dir.exist?

  @tmp_dir
end


# Get where to put temporary shit, most Ruby source code that's been downloaded
# to generate the link maps from.
# 
# @return [Pathname]
# 
def self.tmp_dir &block
  if @tmp_dir.nil?
    self.tmp_dir = repo? ? :gem : :user
  end

  if block
    Dir.chdir @tmp_dir, &block
  else
    @tmp_dir
  end
end


# Run a {Kernel.system}, raising if it fails.
# 
# @param [Array] *args
#   See {Kernel.system}.
# 
# @return [true]
# 
# @raise [SystemCallError]
#   If the command fails.
# 
def self.system! *args
  Kernel.system( *args ).tap { |success|
    unless success
      raise SystemCallError.new \
        %{ Code #{ $?.exitstatus } error executing #{ args.inspect } },
        $?.exitstatus
    end
  }
end


# Make a `GET` request. Follows redirects. Handles SSL.
# 
# @param [String] url
#   What ya want.
# 
# @param [Integer] redirect_limit
#   Max number of redirects to follow before it gives up.
# 
# @return [Net::HTTPResponse]
#   The first successful response that's not a redirect.
# 
# @raise [Net::HTTPError]
#   If there was an HTTP error.
# 
# @raise 
# 
def self.http_get url, redirect_limit = 5
  raise "Too many HTTP redirects" if redirect_limit < 0

  uri = URI url
  request = Net::HTTP::Get.new uri.path
  response = Net::HTTP.start(
    uri.host,
    uri.port,
    use_ssl: uri.scheme == 'https',
  ) { |http| http.request request }
  
  case response
  when Net::HTTPSuccess
    response
  when Net::HTTPRedirection
    http_get response['location'], redirect_limit - 1
  else
    response.error!
  end 
end


# /Namespace
# =======================================================================

end # module LinkStdlib
end # module YARD
