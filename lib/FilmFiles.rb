require "libxml"
require 'rdf'
require 'rdf/vocab'
require 'Base'
require 'Util'

class FilmFiles < Base
  
  BASE_URL="http://www.archive.org/download"
  
  def initialize(film, data)
    super(data)
    
    @film = film
    @id = film.fields["identifier"]
    @uri = RDF::URI.new( Util.canonicalize( "/film/#{film.fields["identifier"]}" ) )
      
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
      
      uri = RDF::URI.new( "#{BASE_URL}/#{@id}/#{file["name"]}" )
        
      case file["format"]
      when "Metadata"
        #Provenance?
      when "Thumbnail"
        add_statement( uri, RDF.type, dcmi_type.Image )
        add_statement( uri, RDF.type, RDF::Vocab::FOAF.Image )
        add_statement( uri, RDF::Vocab::DC.source, @uri )
        add_statement( @uri, RDF::Vocab::FOAF.thumbnail, uri )
        add_statement( uri, RDF::Vocab::DC.title, "Thumbnail image taken from #{@film.fields["title"]}")
      else
         
        add_statement( uri, RDF.type, dcmi_type.MovingImage )
        add_statement( uri, RDF::Vocab::DC.title, "#{@film.fields["title"]} (#{file["format"]})")
        
        if file["format"] != "Animated GIF"
          if file["source"] == "original"
            add_statement( uri, RDF::Vocab::DC.isVersionOf, @uri )
            add_statement( @uri, RDF::Vocab::DC.hasVersion, uri )
          else
            original = RDF::URI.new( "#{BASE_URL}/#{@id}/#{file["original"]}" )
            add_statement( uri, RDF::Vocab::DC.isFormatOf, original )
            add_statement( original, RDF::Vocab::DC.hasFormat, uri )
            
            #also say its a version of the film
            add_statement( uri, RDF::Vocab::DC.isVersionOf, @uri )
            add_statement( @uri, RDF::Vocab::DC.hasVersion, uri )
            
          end  
          
          format = RDF::URI.new( Util.canonicalize( "/format/#{Util.slug(file["format"])}"))
          add_statement( uri, RDF::Vocab::DC.format, format )
          add_statement( format, RDF::RDFS.label, file["format"] )
          add_statement( format, RDF.type, prel.MovieFormat )
                    
        end
        
        add_statement( uri, prel.size, RDF::Literal.new( file["size"] ) )
        add_statement( uri, prel.crc32, RDF::Literal.new( file["crc32"] ) )
        add_statement( uri, prel.sha1, RDF::Literal.new( file["sha1"] ) )
        add_statement( uri, prel.md5, RDF::Literal.new( file["md5"] ) )
        
      end
      
    end
    
    thumbs = []
    @files.each do |file|
      case file["format"]
      when "Thumbnail"
        uri = RDF::URI.new( "#{BASE_URL}/#{@id}/#{file["name"]}" )
        thumbs << uri
      end
    end
    thumbs.sort!()
    if thumbs.length > 0    
      if thumbs.length == 1
        add_statement( @uri, RDF::Vocab::FOAF.depiction, thumbs.first )
      else
        add_statement( @uri, RDF::Vocab::FOAF.depiction, thumbs[1] )
      end
    
    end
        
  end
  
  
end