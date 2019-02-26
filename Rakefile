# frozen_string_literal: true

require 'tempfile'

ORGANIZATION = 'teak'.freeze
ORB_NAME = 'sdk-utils'.freeze

def with_packed_orb
  Tempfile.open('orb') do |file|
    `circleci config pack src > #{file.path}`
    puts "Packed orb to `#{file.path}`"
    yield file.path
  end
end

task :validate do
  with_packed_orb do |orbfile|
    sh "circleci orb validate #{orbfile}", verbose: false
  end
end

task :publish do
  with_packed_orb do |orbfile|
    sh "circleci orb publish #{orbfile} #{ORGANIZATION}/#{ORB_NAME}@dev:alpha", verbose: false
  end
end

task :promote do
  sh "circleci orb publish promote #{ORGANIZATION}/#{ORB_NAME}@dev:alpha patch", verbose: false
end
