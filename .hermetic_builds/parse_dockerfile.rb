#!/usr/bin/env ruby
# Parses ARG declarations in Dockerfile and writes rpms.in.yaml.

require 'yaml'

output         = 'rpms.in.yaml'
repofile       = './ubi.repo'
module_enable  = ['ruby:3.3']
arg_names      = %w[deps devDeps extras]

content = File.read('Dockerfile')

arg_map = {}
content.scan(/^ARG\s+(\w+)="([^"]*)"/) { |name, value| arg_map[name] ||= value }

packages = arg_names.flat_map do |key|
  arg_map.fetch(key, '').split.reject { |p| p.start_with?('-', '$') }
end.sort.uniq

data = {
  'contentOrigin' => { 'repofiles' => [repofile] },
  'arches'        => ['x86_64'],
  'moduleEnable'  => module_enable,
  'packages'      => packages
}

File.write(output, "---\n" + data.to_yaml.sub(/\A---\n/, ''))
puts "Generated #{output} with #{packages.size} packages"
