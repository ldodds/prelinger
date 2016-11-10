$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require 'rubygems'
require 'libxml'
require 'rdf'
require 'Film'
require 'FilmFiles'

File.open("#{ARGV[1]}/files.nt", 'w') do |f|

  Dir.glob("#{ARGV[0]}/files/*.xml") do |file|
    
    data = File.new(file).read
    
    writer = RDF::NTriples::Writer.new( f )
    begin
     film = Film.new( File.new( "#{ARGV[0]}/meta/#{File.basename(file)}" ).read )
     files = FilmFiles.new(film, data)
     statements = files.statements()
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