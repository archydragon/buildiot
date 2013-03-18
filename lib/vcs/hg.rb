#!/usr/bin/env ruby -wKU
# encoding: utf-8

# module for Mercurial

require 'rubygems'
# gem 'mercurial-ruby' suxx

module Hg

  ORIGIN = '/origin'

  # export one branch
  def export(branch)
    if has_branch?(branch)
      Dir.chdir @temp + '/origin'
      target = "#{@temp}/#{branch}/#{@name}"
      `hg checkout --quiet #{branch}`
      `hg archive --type 'files' --quiet #{target}/`
      return target
    else
      throw "No branch named '#{branch}' found"
    end
  end

  private

  # clone remote repo
  def clone(url)
    `hg clone --quiet #{url} #{@temp}#{ORIGIN}`
  end

  # get list of branches
  def branches_read
    @branches = `hg branches -R #{@path} | awk '{print $1}'`.split("\n")
    p @branches
  end

end
