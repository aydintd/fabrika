# encoding: utf-8

require 'benchmark'
require 'English'
require 'json'
require 'open3'
require 'open-uri'
require 'pathname'

CACHE_DIR = File.expand_path(ENV['PACKER_CACHE_DIR'] || '.cache')
ENV['PACKER_CACHE_DIR'] = CACHE_DIR

OUT_DIR = File.expand_path(ENV['PACKER_OUT_DIR'] || '.out')

LOG_DIR = File.expand_path(ENV['PACKER_LOG_DIR'] || '.log')

JSON_OPTS = { max_nesting: false, create_additions: false }

TEMPLATE_FILENAME = 'template.json'
VARIABLE_FILENAME = 'variables.json'
ARTIFACT_DIRNAME  = 'artifact'

Signal.trap('INT') { exit 1 }
STDOUT.sync = true
STDERR.sync = true

def colorize(text, color_code)
  "\033[1m\033[38;5;#{color_code}m#{text}\033[0m"
end

def red(text);    colorize(text, 198); end # rubocop:disable SingleLineMethods

def green(text);  colorize(text, 120); end # rubocop:disable SingleLineMethods

def blue(text);   colorize(text, 117); end # rubocop:disable SingleLineMethods

def yellow(text); colorize(text, 190); end # rubocop:disable SingleLineMethods

def banner(msg)
  puts yellow("*** #{msg}")
end

def info(msg)
  puts green("*** #{msg}")
end

def die(msg)
  puts
  puts red("*** #{msg}")
  exit 1
end

# rubocop:disable MethodLength
def with_logging(logfile, nocolor = false)
  FileUtils.mkdir_p File.dirname(logfile)

  stdout, stderr = STDOUT.clone, STDERR.clone
  [STDOUT, STDERR].each { |f| f.reopen IO.popen "tee #{logfile}", 'w' }
  [STDOUT, STDERR].each { |f| f.sync = true }
  sleep 1
  yield
ensure
  STDOUT.reopen stdout
  STDERR.reopen stderr

  # remove color codes
  if nocolor
    log = File.read(logfile)
    File.open(logfile, 'w') do |f|
      log.gsub!(/\e\[(\d|[;\d])+m/m, '')
      f.write log
    end
  end
end

# Packer template
# rubocop:disable ClassLength
class Template
  attr_reader :file, :path, :name, :dist, :profile

  @checksum_cache = {}
  class << self; attr_accessor :checksum_cache; end

  def initialize(template_file, variant = nil)
    @file = File.expand_path(template_file)
    @path = File.dirname(@file)
    @name = File.basename(@path)
    @dist, @profile = @name.split('-', 2)
  end

  def template
    unless @template
      @template = JSON.parse(File.read(file), JSON_OPTS)
      @template_blob_pristine = JSON.pretty_generate(@template)
    end
    @template
  end

  def update
    Dir.chdir(path) do
      munge
      validate
      save
    end
  end

  # rubocop:disable MethodLength
  def build(variant = nil)
    Dir.chdir(path) do
      old_handler = Signal.trap('INT') do
        cleanup_hack
        exit 1
      end
      cleanup_hack
      packer_run(
        'build', runtime_template, variant || name
      ) || die('Build failed')
      Signal.trap('INT', old_handler)
      move
    end
  end

  def validate(variant = nil)
    Dir.chdir(path) do
      packer_run(
        'validate', runtime_template, variant
      ) || die('Validation failed')
    end
  end

  def move(dest = OUT_DIR)
    return unless dest
    FileUtils.mkdir_p dest unless Dir.exists?(dest)

    (Dir['*.box'] + Dir["#{ARTIFACT_DIRNAME}/*.ova"]).each do |f|
      info "Moving #{f} to #{dest}"
      FileUtils.mv(f, dest) unless f.include?('-production')
    end

    FileUtils.rm_rf ARTIFACT_DIRNAME if Dir.exists?(ARTIFACT_DIRNAME)
  end

  private

  # rubocop:disable MethodLength
  def munge
    template['builders'].each do |h|
      case h['type']
      when 'virtualbox'
        h['name'] = name
        h['vm_name'] = name
        h['output_directory'] = ARTIFACT_DIRNAME
        h['headless'] = false
      when 'kvm', 'qemu'
        h['name'] = "#{name}-production"
      else
        h['name'] = "#{name}-#{h['type']}"
        h['iso_checksum'] = new_checksum(h)
      end
    end
    template['post-processors'].each do |h|
      case h['type']
      when 'vagrant'
        h['output'] = "#{name}.box"
      end
    end
  end

  def save
    if JSON.pretty_generate(template) != @template_blob_pristine
      File.open(file, 'w') do |f|
        f.puts JSON.pretty_generate(template, JSON_OPTS)
      end
      info 'Template file updated.'
    end
  end

  def runtime_template
    template_new = template.clone
    template_new['builders'].each do |h|
      case h['type']
      when 'virtualbox'
        h['headless'] = ENV['DISPLAY'].empty?
      end
    end
    JSON.fast_generate(template_new)
  end

  def packer_run(command, template, variant = nil)
    cmd = %W[packer #{command} -]
    cmd.insert(
      2,
      "-var-file=#{VARIABLE_FILENAME}"
    ) if File.exists?(VARIABLE_FILENAME)
    cmd.insert(
      2,
      "-only=#{variant}"
    ) if variant && variant != 'all'

    FileUtils.mkdir_p CACHE_DIR
    IO.popen cmd, 'w' do |io|
      io.write template
      io.close
    end

    $CHILD_STATUS.success?
  end

  def cleanup_hack
    cmd = "VBoxManage showvminfo --machinereadable #{name} 2>/dev/null"
    result = IO.popen(cmd).find do |line|
      line.chomp!.start_with? 'CfgFile='
    end
    if result
      system("VBoxManage controlvm #{name} poweroff 2>/dev/null")
      system("VBoxManage unregistervm #{name} -delete 2>/dev/null")
      cruft = File.dirname result.gsub(/.+="([^"]+)"/, '\1')
      FileUtils.rm_rf cruft
    end
    Dir.chdir(path) do
      FileUtils.rm_rf ARTIFACT_DIRNAME if Dir.exists?(ARTIFACT_DIRNAME)
    end
  end

  def new_checksum(h)
    url = h['iso_url'] || return
    if url.include?('/current/')
      parse_checksum_from_checksum_file(url)
    else
      h['iso_checksum']
    end
  end

  def parse_current_iso_url_for_checksum_file(url, checksum_file = 'MD5SUMS')
    before, after = url.split '/current/'

    befores = []
    befores << before
    befores << 'current'

    afters = after.split '/'
    befores << afters.shift if afters.first == 'images'
    befores << checksum_file

    [befores.join('/'), afters.join('/')]
  end

  def parse_checksum_from_checksum_file(url)
    self.class.checksum_cache[url] || begin
      checksum_url, rel_path = parse_current_iso_url_for_checksum_file(url)
      checksum_line = open(checksum_url) { |f| f.readlines }.find do |line|
        /\s+[.*\/]*#{rel_path}\s*$/ =~ line
      end || return
      checksum = checksum_line.split.first
      self.class.checksum_cache[url] = checksum
    end
  end
end

# rubocop:disable MethodLength
def specified(task, args)
  dist, profile =
    case task.name
    when 'update', 'validate', 'list', 'clean' then %w(all all)
    else %w(debian vanilla)
    end

  curdir = Pathname.new(Rake.original_dir)
    .relative_path_from(Pathname.new(Dir.pwd)).to_s
  dist, profile = curdir.split('-') unless curdir == '.'

  if args
    dist = args[:dist] if args[:dist]
    profile = args[:profile] if args[:profile]
  end

  [dist, profile]
end

def available_templates
  Dir["[^_]*/#{TEMPLATE_FILENAME}"]
end

def enabled_templates(*args)
  dist, profile = specified(*args)

  available_templates.map { |f| Template.new(f) }.select do |t|
    (dist  == 'all' || dist  == t.dist) &&
    (profile == 'all' || profile == t.profile)
  end
end

desc 'List template(s)'
task :list do |*args|
  enabled_templates(*args).each do |t|
    banner('Available templates:')
    puts
    puts "\t#{t.name}"
  end
end

desc 'Update template(s)'
task :update do |*args|
  enabled_templates(*args).each do |t|
    banner(t.name)
    t.update
  end
end

desc 'Build template(s)'
task :build, :dist, :profile, :variant do |*args|
  enabled_templates(*args).each do |t|
    with_logging(File.join(LOG_DIR, t.name)) do
      banner(t.name)
      time = Benchmark.measure do
        t.build
      end
      info "Finished in #{(time.real / 60).round} minutes."
    end
  end
end

desc 'Validate template(s)'
task :validate, :dist, :profile, :variant do |*args|
  enabled_templates(*args).each do |t|
    banner(t.name)
    t.validate
  end
end

desc 'Clean'
task :clean do |*args|
  (
    Dir['**/packer_cache'] +
    Dir['**/output-vagrant'] +
    Dir["**/#{ARTIFACT_DIRNAME}"] +
    Dir['**/crash.log']
  ).each { |f| rm_rf f }
  rm_rf LOG_DIR if LOG_DIR
end

desc 'Remove everything'
task clobber: :clean do |*args|
  (
    Dir['**/*.(box|ova|vmdk|vdi|raw|qcow[2]?)']
  ).each { |f| rm_rf f }
  rm_rf CACHE_DIR if CACHE_DIR
end

task default: :list
