# frozen_string_literal: true
# encoding: UTF-8


# Namespace
# ========================================================================

module  YARD
module  LinkStdlib


# Definitions
# ========================================================================


# Handling which version of Ruby to link against.
# 
module RubyVersion

  # Constants
  # ----------------------------------------------------------------------------

  # Support for 2.2.X ended March 28, 2017. 2.3 is scheduled to go March 2019. 
  # 
  # https://www.ruby-lang.org/en/news/2018/06/20/support-of-ruby-2-2-has-ended/
  # 
  # @return [Gem::Version]
  # 
  MINIMUM_SUPPORTED = Gem::Version.new '2.3.0'


  # As of 2018.09.23, the latest stable release
  # 
  # @return [Gem::Version]
  # 
  LATEST_STABLE = Gem::Version.new '2.5.1'


  # Whatever version we're running here and now.
  # 
  # @return [Gem::Version]
  # 
  CURRENT_RUNTIME = Gem::Version.new RUBY_VERSION


  # If no-one tells us different then use the minimum supported Ruby version.
  # 
  # @return [Symbol]
  # 
  DEFAULT_FALLBACK_MODE = :minimum_supported


  # Class Methods
  # ========================================================================

  # Set what version of Ruby to link to.
  # 
  # @param [#to_s] version
  #   Something that's string representation is the version you want to set.
  #   
  #   Note that {Gem::Version} works fine here 'cause it's string rep is the
  #   version string, effectively meaning a frozen copy of it is stored.
  # 
  # @return [Gem::Version]
  #   The newly set value. Is frozen.
  # 
  def self.set version
    @ruby_version = Gem::Version.new version
  end


  # Get what version of Ruby is set to link to.
  # 
  # @return [Gem::Version]
  #   Returns the actual in`stance var reference, but it's frozen, so it should
  #   be reasonably OK.
  # 
  def self.get
    @ruby_version || min_required || fallback
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
  # @return [Gem::Version]
  # 
  def self.minor version = self.get
    Gem::Version.new \
      ( version.segments[0..1] + [0] ).map( &:to_s ).join( '.' )
  end


  # Set the fallback mode that is used to pick a version of Ruby to link against
  # when no value is provided by the developer and we couldn't figure one out
  # we were happy with from the gemspec.
  # 
  # @param [:minimum_supported, :latest_stable, :current_runtime] value
  #   Just picks which of these versions {#fallback} will use:
  #   
  #   1.  {MINIMUM_SUPPORTED}
  #   2.  {LATEST_STABLE}
  #   3.  {CURRENT_RUNTIME}
  # 
  # @return [:minimum_supported, :latest_stable, :current_runtime]
  #   The value that was just set.
  # 
  def self.fallback_mode= value
    unless [  :minimum_supported,
              :latest_stable,
              :current_runtime ].include? value
      raise ArgumentError,
        "Fallback-mode must be one of :minimum_supported, :latest_stable, " +
        "or :current_runtime; found #{ value.inspect }"
    end

    @fallback_mode = value
  end


  # Gets the fallback mode. Uses {DEFAULT_FALLBACK_MODE} if one was never set.
  # 
  # More details available in {.fallback_mode=} and {.fallback}.
  # 
  # @return [:minimum_supported, :latest_stable, :current_runtime]
  #   The value that was just set.
  # 
  def self.fallback_mode
    @fallback_mode || DEFAULT_FALLBACK_MODE
  end


  # Used as last-resort to pick a version of Ruby to link against, after 
  # looking for a user-provided value and trying {.min_required}.
  # 
  # Simply selects between
  # 
  # 1.  {MINIMUM_SUPPORTED}
  # 2.  {LATEST_STABLE}
  # 3.  {CURRENT_RUNTIME}
  # 
  # Depending on {.fallback_mode}.
  # 
  # @return [Gem::Version]
  #   Fallback Ruby version to use.
  # 
  def self.fallback
    case fallback_mode
    when :minimum_supported
      MINIMUM_SUPPORTED
    when :latest_stable
      LATEST_STABLE
    when :current_runtime
      CURRENT_RUNTIME
    else
      raise RuntimeError,
        "Bad value #{ fallback_mode.inspect } at " +
        "{YARD::LinkStdlib::RubyVersion.fallback_mode}, " +
        "expected :minimum_supported, :latest_stable or :current_runtime"
    end
  end


  # Try to get the minimum required Ruby version from the gemspec (the 
  # {Gem::Specification#required_ruby_version} attribute).
  # 
  # @return [nil]
  #   If we
  #   
  #   1.  didn't find any {Gem::Specification#required_ruby_version} values, or
  #       
  #   2.  couldn't figure a reasonable version out given what we found.
  #       
  #       This method uses a very simple approach, on the hypothesis that almost 
  #       all real-world configurations will be really simple, and that it's 
  #       more practical for the few that for some reason have some baffling 
  #       requirement config to just explicitly specify what Ruby version they
  #       want to use.
  # 
  # @return [Gem::Version]
  #   If we successfully determined a minimum required Ruby version that seems
  #   to make some sense to link to.
  # 
  def self.min_required
    # Load gemspecs in this dir that have required Ruby versions. There should
    # probably only ever be one, but what they hell this is just as easy as
    # any other handling I thought of off the top of my head...
    specs = Dir[ './*.gemspec' ].
      map { |path|  Gem::Specification.load path }.
      select { |spec|
        spec.required_ruby_version && !spec.required_ruby_version.none?
      }

    # If we didn't find anything useful just assume the gem supports the oldest
    # supported Ruby version and link to that
    return nil if specs.empty?

    # Map to their {Gem::Requirement} instances
    reqs = specs.map &:required_ruby_version

    req_arrays = reqs.
      map( &:requirements ).  # => Array<Array<Array<(String, Gem::Version)>>>
      flatten( 1 ).           # => Array<Array<(String, Gem::Version)>>
      select { |(restriction, version)|
        # We only look at exact `=`, and the "greater-than" ones where we can
        # potentially use the version (with `>` for instance we need to know 
        # if another patch version exists *after* it so we know what to bump
        # it too, and I ain't gonna deal with that tonight)
        case restriction
        when '=', '>=', '~>'
          true
        end
      }.                      # => Array<Array<(String, Gem::Version)>>
      map( &:last ).          # => Array<Gem::Version>
      sort. # So we have min first
      # Then find the first one that satisfies all the {Gem::Requirements},
      # or `nil` if none do
      find { |version| reqs.all? { |req| req.satisfied_by? version } }

  end # min_required

end # module RubyVersion

# /Namespace
# ========================================================================

end # module LinkStdlib
end # module YARD
