#!/usr/bin/env ruby

require 'pathname'
require 'fileutils'
require 'zlib'

require 'rdoc/rdoc'

GEM_ROOT = Pathname.new( __dir__ ).join( '..' ).expand_path

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
    
    @options.visibility = :nodoc

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
  end # #almost_document
end # class RDoc::RDoc

def main args
  src = Pathname.new( args.shift ).expand_path
  dest = Pathname.new( args.shift ).expand_path
  
  puts "src: #{ src.inspect }"
  puts "dest: #{ dest.inspect }"

  # RDoc needs this output dir arg in `ARGV` or it will bail out with an error
  # due to `//doc` existing, even though we don't ever actually write to any of
  # it.
  unless args.include? '--op'
    args << '--op'
    args << '/tmp/not_actually_used'
  end

  Dir.chdir src

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

  FileUtils.mkdir_p( dest.dirname ) unless dest.dirname.exist?

  Zlib::GzipWriter.open dest do |gz|
    gz.write JSON.pretty_generate( map )
  end
end

# Kickoff!
main( ARGV ) if __FILE__ == $0
