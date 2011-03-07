require 'rubygems'
require 'rake'
require 'rake/clean'

CACHE_DIR="data/cache"
RDF_DIR="data/nt"

CLEAN.include ["#{RDF_DIR}/*.nt", "#{RDF_DIR}/*.gz"]

#Helper function to create data dirs
def mkdirs()
  if !File.exists?("data")
    Dir.mkdir("data")
  end  
  if !File.exists?(CACHE_DIR)
    Dir.mkdir(CACHE_DIR)
  end
  if !File.exists?(RDF_DIR)
    Dir.mkdir(RDF_DIR)
  end
end

task :init do
  mkdirs()      
end

#cache manifest
task :download => [:init] do
  sh %{ ruby bin/cache.rb #{CACHE_DIR} }
end

task :convert_static do
  Dir.glob("etc/static/*.ttl").each do |src|
      sh %{rapper -i turtle -o ntriples #{src} >#{RDF_DIR}/#{File.basename(src, ".ttl")}.nt}
  end
end

task :convert_films do
  sh %{ruby bin/convert_films.rb #{CACHE_DIR} #{RDF_DIR}}
end

task :convert_files do
  sh %{ruby bin/convert_files.rb #{CACHE_DIR} #{RDF_DIR}}
end

task :convert_reviews do
  sh %{ruby bin/convert_reviews.rb #{CACHE_DIR} #{RDF_DIR}}
end

task :convert => [:init, :convert_static, :convert_films, :convert_files, :convert_reviews]

task :package do
  sh %{gzip #{RDF_DIR}/*} 
end

task :publish => [:download, :convert, :package]