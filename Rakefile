# frozen_string_literal: true

require 'tempfile'

ORGANIZATION = 'teak'.freeze
ORB_NAME = 'sdk-utils'.freeze

def with_packed_orb
  Tempfile.open('orb') do |file|
    `circleci orb pack src > #{file.path}`
    puts "Packed orb to `#{file.path}`"
    yield file.path
  end
end

def promote(label:, version:, verbose: false)
  sh "circleci orb publish promote #{ORGANIZATION}/#{ORB_NAME}@#{label} #{version}", verbose: verbose
end

desc 'Validate the orb'
task :validate do
  with_packed_orb do |orbfile|
    sh "circleci orb validate #{orbfile}", verbose: false
  end
end

desc 'Publish the orb to the dev:alpha tag'
task :publish do
  with_packed_orb do |orbfile|
    sh "circleci orb publish #{orbfile} #{ORGANIZATION}/#{ORB_NAME}@dev:alpha", verbose: false
  end
end

desc 'Promote the version at dev:alpha to production and bump the patch release'
namespace :promote do
  %w[patch minor major].each do |version|
    desc "Promote dev:alpha to production and bump the #{version} in version"
    task version.to_sym do
      promote(label: 'dev:alpha', version: version)
    end
  end

  task :default => :patch
end
