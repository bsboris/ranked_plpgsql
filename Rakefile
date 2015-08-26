require "rake/testtask"

$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)

require "ranked_benchmark"

Rake::TestTask.new do |t|
  t.libs << "test"
  t.pattern = "test/*_test.rb"
end

task :default => :test

task :bench do
  RankedBenchmark.new.run
end
