#!/usr/bin/env ruby -wKU
# encoding: utf-8

###   HERE BE DRAGONS   ###

require 'rubygems'
require 'optparse'
require 'zlib'
require 'json'
require './lib/git.rb'
require './lib/deb.rb'

class Buildiot

  CACHEDIR = ENV['HOME'] + '/.buildiot/'
  BUILDS   = CACHEDIR + 'builds'

  REQUIRED = ['name', 'source', 'maintainer', 'versions', 'destination']
  DEFAULT  = ['outdir', 'description', 'arch']
  OPTIONAL = ['conffiles', 'deps', 'predeps', 'builddeps', 'dirs', 'prebuild']
  SCRIPTS  = ['preinst', 'postinst', 'prerm', 'postrm']

  (REQUIRED + DEFAULT + OPTIONAL + SCRIPTS).each { |key| attr_accessor key.to_sym }

  def run!
    buildcache_read
    @default = rules_read(ARGV[0])
    @temp = "/tmp/buildiot-#{@name}-#{randomhash}"
    Dir.mkdir @temp
    repo = Git.new(@source, @temp, @name) # FIXME
    @versions.each do |version|
      @build = get_build("#{@name}_#{version[0]}") + 1
      rules_custom version[1]
      @dataroot = repo.export version[1]['branch']
      package = Deb.new(@name, version[0], @build, @maintainer, @description)
      package.arch_set(@arch) unless @arch == 'all'
      package.gen_deps(@deps, @predeps, @builddeps)
      package.directory_set(@temp + '/' + @name)
      package.prebuild(@dataroot, @prebuild)
      package.scripts(@dataroot, @preinst, @postinst, @prerm, @postrm)
      package.data_add(@dataroot, @destination)
      package.gen_conffiles(@conffiles)
      package.gen_dirs(@dirs)
      package.pack(@outdir)
      puts "Package #{package.filename} — build OK"
      rules_reset @default
      save_build("#{@name}_#{version[0]}")
    end
    FileUtils.rm_rf @temp
  end

  private

  # get last build number for package from cache file
  def get_build(package)
    if @builds[package].nil?
      0
    else
      @builds[package]
    end
  end

  # save build caches
  def save_build(package)
    @builds[package] = @build
    IO.write(BUILDS, JSON.generate(@builds))
  end

  # read build caches
  def buildcache_read
    if !Dir.exists?(CACHEDIR)
      FileUtils.mkdir CACHEDIR
      IO.write(BUILDS, '{}')
    end
    @builds = JSON.parse(IO.read(BUILDS))
  end

  # get rules from file
  def rules_read(file)
    rules = JSON.parse(IO.read(file))
    rules_reset rules
    return rules
  end

  # reset rules to global defaults
  def rules_reset(rules)
    REQUIRED.each do |id|
      if !rules[id].nil?
        self.send("#{id}=", rules[id])
      else
        throw "Missing required option \'#{id}\' in rules file"
      end
    end
    self.outdir      = rules['outdir'] ||= Dir.pwd
    self.description = rules['description'] ||= "Package generated with Buildiot."
    self.arch        = rules['arch'] ||= 'all'
    (OPTIONAL + SCRIPTS).each do |id|
      self.send("#{id}=", rules[id])
    end
  end

  # apply rules specific for current version
  def rules_custom(data)
    allowed = DEFAULT + OPTIONAL + SCRIPTS + ['destination']
    allowed.each do |over|
      fill over, data[over]
    end
  end

  # divine random
  def randomhash
    Zlib::crc32(Time.now.to_s).to_s(16)
  end

  # it's all for overriding
  def fill(field, value)
    if !value.nil?
      self.send("#{field}=", value)
    end
  end

end

build = Buildiot.new
build.run!
