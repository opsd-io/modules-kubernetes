#!/usr/bin/env ruby
# frozen_string_literal: true

require "digest"
require "open3"
require "tmpdir"
require "yaml"

ROOT = File.expand_path("..", __dir__)

def run!(*command)
  stdout, stderr, status = Open3.capture3(*command)
  return stdout if status.success?

  details = [stderr.strip, stdout.strip].reject(&:empty?).join("\n")
  raise "Command failed (#{command.join(' ')}):\n#{details}"
end

def module_files
  Dir.glob(File.join(ROOT, "modules", "**", "module.yaml")).sort
end

files = module_files
raise "No module metadata files found under modules/." if files.empty?

helm_modules = files.filter_map do |metadata_path|
  data = YAML.safe_load_file(metadata_path, aliases: false)
  source = data.dig("spec", "source")
  next unless source.is_a?(Hash) && source["type"] == "helm"

  [metadata_path, data, source]
end

if helm_modules.empty?
  puts "No Helm modules to validate."
  exit 0
end

helm_modules.each do |metadata_path, data, source|
  module_dir = File.dirname(metadata_path)
  module_id = data.dig("metadata", "id")
  chart = source.fetch("chart")
  version = source.fetch("version")
  repository = source.fetch("repository")
  expected_digest = source.fetch("digest")
  defaults_path = File.expand_path(data.dig("spec", "defaults"), module_dir)
  raise "Invalid defaults path in #{metadata_path}" unless defaults_path.start_with?("#{module_dir}/")
  raise "Defaults file not found: #{defaults_path}" unless File.file?(defaults_path)

  Dir.mktmpdir("opsd-helm-") do |directory|
    run!("helm", "pull", chart, "--repo", repository, "--version", version, "--destination", directory)
    archive = File.join(directory, "#{chart}-#{version}.tgz")
    actual_digest = "sha256:#{Digest::SHA256.file(archive).hexdigest}"
    raise "Chart digest mismatch for #{module_id}: expected #{expected_digest}, got #{actual_digest}" unless actual_digest == expected_digest

    run!("helm", "lint", archive, "--values", defaults_path, "--kube-version", "1.25.0")
    run!("helm", "template", module_id, archive, "--namespace", "argocd", "--values", defaults_path,
         "--kube-version", "1.25.0", "--include-crds")
  end

  puts "Validated Helm module #{module_id} (#{chart} #{version})."
end
