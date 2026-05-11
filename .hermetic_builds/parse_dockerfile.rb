#!/usr/bin/env ruby
# Parses ARG declarations in Dockerfile and writes rpms.in.yaml.

content = File.read('Dockerfile')

arg_map = {}
content.scan(/^ARG\s+(\w+)="([^"]*)"/) do |name, value|
  arg_map[name] ||= value
end

packages = %w[deps devDeps extras].flat_map do |key|
  arg_map.fetch(key, '').split.reject { |p| p.start_with?('-', '$') }
end.sort.uniq

File.write('rpms.in.yaml', [
  'contentOrigin:',
  '  repofiles:',
  '  - ./ubi.repo',
  'arches:',
  '- x86_64',
  'moduleEnable:',
  '- ruby:3.3',
  'packages:',
  *packages.map { |p| "- #{p}" }
].join("\n") + "\n")

puts "Generated rpms.in.yaml with #{packages.size} packages"
