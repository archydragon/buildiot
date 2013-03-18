#!/usr/bin/env ruby -wKU
# encoding: utf-8

# VCS managing class

require 'rubygems'
require './lib/vcs/git.rb'
require './lib/vcs/hg.rb'

class VCS

  # prefixes for URLs to remote repos
  REMPREFIXES = [
    'http',
    'https',
    'ftp',
    'ftps',
    'ssh',
    'git',
    'hg',
    'ssh+git',
    'ssh+hg',
    'rsync',
    'file',
  ]

  ORIGIN = '/origin'

  def initialize(vcs, path, temp, name)
    case vcs
    when 'git'
      extend Git
    when 'hg'
      extend Hg
    else
      throw "VCS '#{vcs}' isn't supported."
    end
    @temp = temp
    @name = name
    if REMPREFIXES.any? { |prefix| path =~ /^#{prefix}\:\/\// }
      remote(path)
    else
      @path = path
      local()
    end
  end

  # return all the branches belong to repo
  def branches
    return @branches
  end

  # return 'true' if the branch with requested name is present under repo
  def has_branch?(branch)
    return @branches.include?(branch)
  end

  private

  # use remote git repo
  def remote(url)
    clone(url)
    @path = @temp + ORIGIN
    branches_read
  end

  # use local directory as git repo
  def local
    if !Dir.exists?(@path)
      throw "Unable to access directory #{@path}"
    end
    FileUtils.ln_s @path, @temp + ORIGIN
    branches_read
  end

end
