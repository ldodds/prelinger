require 'rubygems'

require 'open-uri'
require 'json'

SEARCH = '(collection:prelinger+OR+mediatype:prelinger)+AND+-mediatype:collection'

ALL_FIELDS = '&fl[]=avg_rating&fl[]=call_number&fl[]=collection&fl[]=contributor&fl[]=coverage&fl[]=creator&fl[]=date&fl[]=description&fl[]=downloads&fl[]=foldoutcount&fl[]=format&fl[]=headerImage&fl[]=identifier&fl[]=imagecount&fl[]=language&fl[]=licenseurl&fl[]=mediatype&fl[]=month&fl[]=num_reviews&fl[]=oai_updatedate&fl[]=publicdate&fl[]=publisher&fl[]=rights&fl[]=scanningcentre&fl[]=source&fl[]=subject&fl[]=title&fl[]=type&fl[]=volume&fl[]=week&fl[]=year'
ID_FIELD_ONLY = '&fl[]=identifier'

def mkdirs
  ['meta', 'reviews', 'files'].each do |dir|
    if !File.exists?("#{ARGV[0]}/#{dir}")
      Dir.mkdir("#{ARGV[0]}/#{dir}")
    end    
  end
end

def fetch_ids(fields, rows='50')
  url = URI.parse( "http://www.archive.org/advancedsearch.php?q=#{SEARCH}#{fields}&rows=#{rows}&page=1&output=json&save=yes")  
  url.read
end

def fetch_file(id, type='meta')
  url = URI.parse( "http://www.archive.org/download/#{id}/#{id}_#{type}.xml" )
  url.read
end

def crawl(json)
  puts "Crawling #{ json['response']['numFound'] } records"
  json['response']['docs'].each do |result|
    puts result['identifier']
    ['meta', 'files', 'reviews'].each do |stage|
      begin
        if !File.exists?("#{ARGV[0]}/#{stage}/#{result['identifier']}.xml")
          data = fetch_file( result['identifier'], stage )
          File.open( "#{ARGV[0]}/#{stage}/#{result['identifier']}.xml", 'w') do |f|
            f.puts( data )
          end
        end
      rescue => e
        puts e
        #puts e.backtrace
        puts "Failed to fetch #{result['identifier']} #{stage}"
      end      
    end
  end
end

mkdirs

#cache identifiers locally
File.open("#{ARGV[0]}/ids.json", 'w') do |f|
  f.puts fetch_ids(ID_FIELD_ONLY, 7000)
end

#parse and crawl
json = JSON.load( File.new( "#{ARGV[0]}/ids.json") )
crawl(json)
