require "libxml"
require 'rdf'
require 'Base'
require 'Util'

class FilmFiles < Base
  
  BASE_URL="http://www.archive.org/download"
  
  def initialize(film, data)
    super(data)
    
    @film = film
    @id = film.fields["identifier"]
    @uri = RDF::URI.new( "#{BASE_URL}/#{film.fields["identifier"]}" )
      
    @files = []
    @root.find("file").each do |tag|
      file = {}
      ["format", "original", "md5", "mtime", "size", "crc32", "sha1"].each do |t|
        file[t] = read_tag(t, tag)
      end
      file["source"] = tag["source"]
      file["name"] = tag["name"]
      @files << file
    end
  
    generate_statements()
      
  end
  
  def generate_statements()
    
    dcmi_type = RDF::Vocabulary.new( "http://purl.org/dc/dcmitype/")
    prel = RDF::Vocabulary.new(Util.canonicalize("/schema/"))
      
    @statements = []
    @files.each do |file|
      
      uri = RDF::URI.new( Util.canonicalize( "/film/#{@id}/#{file["name"]}"))
        
      case file["format"]
      when "Metadata"
        #Provenance?
      when "Thumbnail"
        add_statement( uri, RDF.type, dcmi_type.Image )
        add_statement( uri, RDF.type, RDF::FOAF.Image )
        add_statement( uri, RDF::DC.source, @uri )
        add_statement( @uri, RDF::FOAF.thumbnail, uri )
        add_statement( uri, RDF::DC.title, "Thumbnail image taken from #{@film.fields["title"]}")        
      else
         
        add_statement( uri, RDF.type, dcmi_type.MovingImage )
        add_statement( uri, RDF::DC.title, "#{@film.fields["title"]} (#{file["format"]})")
        
        if file["format"] != "Animated GIF"
          if file["source"] == "original"
            add_statement( uri, RDF::DC.isVersionOf, @uri )
            add_statement( @uri, RDF::DC.hasVersion, uri )
          else
            original = RDF::URI.new( Util.canonicalize( "/film/#{@id}/#{file["original"]}" ) )
            add_statement( uri, RDF::DC.isFormatOf, original )
            add_statement( original, RDF::DC.hasFormat, uri )
          end  
          
          format = RDF::URI.new( Util.canonicalize( "/format/#{Util.slug(file["format"])}"))
          add_statement( uri, RDF::DC.format, format )
          add_statement( format, RDF::RDFS.label, file["format"] )
          add_statement( format, RDF.type, prel.MovieFormat )
                    
        end
        
        add_statement( uri, prel.size, RDF::Literal.new( file["size"] ) )
        add_statement( uri, prel.crc32, RDF::Literal.new( file["crc32"] ) )
        add_statement( uri, prel.sha1, RDF::Literal.new( file["sha1"] ) )
        add_statement( uri, prel.md5, RDF::Literal.new( file["md5"] ) )
        
      end
      
    end
    
    #FIXME sort thumbnails?
    
  end
  
  
end