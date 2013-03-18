#!/usr/bin/env ruby -wKU
# encoding: utf-8

# module for Git

require 'rubygems'
require 'rugged'
require 'fileutils'

module Git

  ORIGIN = '/origin'

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

  # clone remote repo
  def clone(url)
    `git clone --quiet #{url} #{@temp}#{ORIGIN}`
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
