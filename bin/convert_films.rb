$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require 'rubygems'
require 'libxml'
require 'rdf'
require 'Film'

File.open("#{ARGV[1]}/films.nt", 'w') do |f|

  Dir.glob("#{ARGV[0]}/meta/*.xml") do |file|
    
    data = File.new(file).read
    
    writer = RDF::NTriples::Writer.new( f )
    begin
     film = Film.new(data)
     statements = film.statements()
     statements.each do |stmt|
        writer << stmt
    end
    rescue StandardError => e
      puts "Failed to convert #{file}"
      puts e
      puts e.backtrace
    end
    
  end

end