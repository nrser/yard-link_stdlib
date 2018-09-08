#!/usr/bin/env ruby

require 'pathname'
require 'rdoc/rdoc'

# Get paths in order - we want to be in the Ruby repo checkout
GEM_ROOT = Pathname.new( __dir__ ).join( '..' ).expand_path
REPO = GEM_ROOT.join 'tmp', 'ruby'

class RDoc::RDoc
  # Pretty much a copy of `RDoc::RDoc#document`, just with the `#generate` step
  # commented-out.
  def almost_document options = ARGV
    self.store = RDoc::Store.new

    if RDoc::Options === options then
      @options = options
      @options.finish
    else
      @options = load_options
      @options.parse options
    end

    if @options.pipe then
      handle_pipe
      exit
    end

    unless @options.coverage_report then
      @last_modified = setup_output_dir @options.op_dir, @options.force_update
    end

    @store.encoding = @options.encoding
    @store.dry_run  = @options.dry_run
    @store.main     = @options.main_page
    @store.title    = @options.title
    @store.path     = @options.op_dir

    @start_time = Time.now

    @store.load_cache

    file_info = parse_files @options.files

    @options.default_title = "RDoc Documentation"

    @store.complete @options.visibility

    @stats.coverage_level = @options.coverage_report

    gen_klass = @options.generator

    @generator = gen_klass.new @store, @options

    # generate
    nil
  end
end

def main args
  dest = Pathname.new( args.shift ).expand_path

  puts "dest: #{ dest.inspect }"

  Dir.chdir REPO

  rd = RDoc::RDoc.new

  rd.almost_document args

  map = {}

  rd.store.all_classes_and_modules.each do |mod|
    map[mod.full_name] = mod.path

    mod.class_method_list.each do |class_method|
      map[class_method.full_name] = class_method.path
    end

    mod.instance_method_list.each do |instance_method|
      map[instance_method.full_name] = instance_method.path
    end
  end

  dest.open 'w' do |f|
    f.write JSON.dump( map )
  end
end

# Kickoff!
main( ARGV ) if __FILE__ == $0
