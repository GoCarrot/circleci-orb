# frozen_string_literal: true

ORGANIZATION = 'teak'.freeze
ORB_NAME = 'sdk-utils'.freeze

task :validate do
  sh 'circleci orb validate orb.yml'
end

task :publish do
  sh "circleci orb publish orb.yml #{ORGANIZATION}/#{ORB_NAME}@dev:first"
end
