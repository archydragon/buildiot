#!/usr/bin/env ruby -wKU
# encoding: utf-8

# class for Debian packages

require 'rubygems'
require 'fileutils'

class Deb

  # YOU MUST CONSTRUCT ADDITIONAL PYLONS
  def initialize(name, version, build, maintainer, description)
    @name        = name
    @version     = version
    @build       = build
    @size        = 0
    @maintainer  = maintainer
    @description = description
    @arch        = 'all'
  end

  # return filename of the package will built with
  def filename
    return "#{@name}_#{@version}-#{@build}_#{@arch}.deb"
  end

  # change architecture of package
  def arch_set(arch)
    @arch = arch
  end

  # set the directory package data will be collected under and create structure for them
  def directory_set(dir)
    @directory = dir
    FileUtils.rm_rf @directory
    Dir.mkdir @directory
    chdir
    Dir.mkdir 'DEBIAN'
  end

  def data_add(dataroot, datahash)
    datahash.each do |item|
      fsprefix = item[0].gsub(/^\//, '')
      chdir
      FileUtils.mkdir_p fsprefix unless Dir.exists?(fsprefix)
      files = item[1].split(';')
      if files.kind_of?(String)
        files = [files]
      end
      files.each do |file|
        file = file.strip
        path = dataroot + '/' + file
        @size += `du -sk #{path}`.split[0].to_i
        data = Dir.glob(dataroot + '/' + file)
        FileUtils.cp_r data, fsprefix
      end
    end
  end

  # generate dependencies
  def gen_deps(deps_list = nil, predeps_list = nil, builddeps_list = nil)
    @deps  = ''
    @deps += "Depends: #{deps_list.join(', ')}\n" unless deps_list.nil?
    @deps += "Pre-Depends: #{predeps_list.join(', ')}\n" unless predeps_list.nil?
    @deps += "Build-Depends: #{builddeps_list.join(', ')}\n" unless builddeps_list.nil?
  end

  # generate conffiles
  def gen_conffiles(filelist)
    gen_list('conffiles', filelist)
  end

  # generate empty directories list
  def gen_dirs(dirslist)
    gen_list('dirs', dirslist)
  end

  # copy scripts
  def scripts(dataroot, preinst = nil, postinst = nil, prerm = nil, postrm = nil)
    chdir
    {:preinst => preinst, :postinst => postinst, :prerm => prerm, :posrtm => postrm}.each_pair do |key, script|
      if !script.nil?
        target = "DEBIAN/#{key.to_s}"
        if script.scan(/^\//).empty?
          FileUtils.cp "#{dataroot}/#{script}", target
        else
          FileUtils.cp "#{script}", target
        end
        FileUtils.chmod "+x", target
      end
    end
  end

  # execute script before package build (e.g. compile sources)
  def prebuild(dataroot, what)
    if !what.nil?
      Dir.chdir dataroot
      `#{what}`
    end
  end

  # make .deb package
  def pack(outdir)
    chdir
    gen_control
    gen_md5
    Dir.chdir '..'
    `dpkg-deb -b #{@name} #{outdir}/#{filename}`
  end

  private

  # go root directory of the package data
  def chdir
    Dir.chdir @directory
  end

  # generate file with strings list
  def gen_list(name, list)
    if !list.nil?
      list = list.join("\n") + "\n"
      chdir
      IO.write('DEBIAN/' + name, list)
    end
  end

  # generate control file
  def gen_control
    @description = @description.join("\n ")
    control = <<CTRLVAR
Package: #{@name}
Version: #{@version}
Maintainer: #{@maintainer}
Architecture: #{@arch}
Installed-Size: #{@size}
Description: #{@description}
CTRLVAR
    control += @deps
    chdir
    IO.write('DEBIAN/control', control)
  end

  # generate md5sums for package content
  def gen_md5
    chdir
    FileUtils.touch 'DEBIAN/md5sums'
    Dir.foreach('.') do |item|
      next if item == '.' or item == '..' or item == 'DEBIAN'
      `md5deep -rl #{item} >> DEBIAN/md5sums`
    end
  end

end
