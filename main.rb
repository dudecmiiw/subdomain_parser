#!/bin/ruby

require 'openssl'
require 'net/http'
require 'nokogiri'
require 'set'

require_relative 'requestor'
require_relative 'subdomain_parser'
require_relative 'subdomain_validator'

DEBUG     = false.freeze
VALIDATOR = false.freeze

OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

if DEBUG
  ENV['http_proxy'] = 'http://127.0.0.1:8080'
end

start = Time.now

domain = '' #ex: example.com

sources = [
  'crtsh',
  'hacker_target',
  'osintsh'
]

if VALIDATOR
  validator_jobs = Queue.new
end

subdomains = Set[]

subdomain_parser = SubdomainParser.new(domain)

thread_parser = sources.map do |source|
  Thread.new do
    Thread.current.name = source
    
    tmp = subdomain_parser.parse_from(source)

    if VALIDATOR
      tmp.each do |_tmp|
        validator_jobs << _tmp
      end
    else
      subdomains.merge tmp
    end
  end
end

thread_parser.map(&:join)

if VALIDATOR
  VALIDATOR_WORKER = 20.freeze
  thread_validator = VALIDATOR_WORKER.times.map do 
    Thread.new do
      while not validator_jobs.empty?
        subdomains_to_validate = validator_jobs.pop(true)
  
        subdomains.concat SubdomainValidator.visit_http_or_https(subdomains_to_validate)
      end
    end
  end
  
  thread_validator.map(&:join)
end

subdomains.each do |subdomain|
  puts subdomain
end

finish = Time.now
diff = finish - start

puts "Finish at #{diff}"
