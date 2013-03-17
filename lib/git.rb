#!/usr/bin/env ruby -wKU
# encoding: utf-8

# class for Git

require 'rubygems'
require 'rugged'
require 'fileutils'

class Git

  # prefixes for URLs to remote repos
  REMPREFIXES = [
    'http',
    'https',
    'ftp',
    'ftps',
    'ssh',
    'git',
    'ssh+git',
    'rsync',
    'file',
  ]

  # CONSTRUCTION COMPLETE
  def initialize(path, temp, name)
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

  # export one branch
  def export(branch)
    if has_branch?(branch)
      Dir.chdir @temp + '/origin'
      target = "#{@temp}/#{branch}/#{@name}"
      `git checkout --quiet origin/#{branch}`
      `git checkout-index --quiet --all --prefix=#{target}/`
      return target
    else
      throw "No branch named '#{branch}' found"
    end
  end

  private

  # use remote git repo
  def remote(url)
    `git clone --quiet #{url} #{@temp}/origin`
    @path = @temp + "/origin"
    branches_read
  end
  
  # use local directory as git repo
  def local
    if !Dir.exists?(@path)
      throw "Unable to access directory #{@path}"
    end
    FileUtils.ln_s @path, @temp + "/origin"
    branches_read
  end

  # get list of branches
  def branches_read
    @repo = Rugged::Repository.new(@path)
    branchlist = []
    @repo.refs.each do |ref|
      if !ref.scan(/origin/).empty?
        tag = ref.split('/').last
        branchlist.push tag
      end
    end
    @branches = branchlist
  end

end
