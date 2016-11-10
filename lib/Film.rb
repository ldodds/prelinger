require "libxml"
require 'rdf'
require 'rdf/vocab'
require 'Base'
require 'Util'

class Film < Base
  
  FIELDS = ["identifier", "creator", "description", "date", 
    "color", "sound", "title", "sponsor", "runtime", "country", 
     "subject", "numeric_id", "shotlist", "type"]

  attr_reader :statements
  attr_reader :fields
  
  def initialize(data)
    super(data)
    
    @fields = {}
    FIELDS.each do |field|
      @fields[field] = read_tag(field)
    end
    
    @uri = RDF::URI.new( Util.canonicalize("/film/#{@fields["identifier"]}"))
    
    normalize_color() if @fields["color"]
    normalize_sound() if @fields["sound"]
    normalize_subject() if @fields["subject"]
    normalize_runtime() if @fields["runtime"]     
    generate_statements()
    
      
  end

  #b&amp;w
  #B&amp;W
  #B&amp;W/C
  #b/w
  #B/W
  #C
  #color  
  def normalize_color()
    @fields["color"] = @fields["color"].upcase
    @fields["color"] = "COLOR" if @fields["color"] == "C"
    @fields["color"] = @fields["color"].sub("/", "&")  
    @fields["color"] = ["B&W", "COLOR"] if @fields["color"] == "B&W&C"    
  end

  #Sd
  #Si
  #silent
  #sound
  def normalize_sound()
    @fields["sound"] = @fields["sound"].upcase
    @fields["sound"] = "SILENT" if @fields["sound"] = "SI"
    @fields["sound"] = "SOUND" if @fields["sound"] = "SD"
  end

  def normalize_subject()
    @fields["subject"] = @fields["subject"].split(";")
  end

  def normalize_runtime()
    @fields["runtime"] = "00#{@fields["runtime"]}" if @fields["runtime"].start_with?(":")
    @fields["runtime"] = "0#{@fields["runtime"]}" if @fields["runtime"].start_with?("0:")
    @fields["runtime"] = "0#{@fields["runtime"]}" if @fields["runtime"].match(/\d+\:/)
    @fields["runtime"] = "PT#{@fields["runtime"].sub(":", "M")}S"
  end      
  
  def add_literal(predicate, field)
    if @fields[field]
      add_property( predicate , RDF::Literal.new(@fields[field]))
    end
  end
      
  
  def generate_statements()
    @statements = []
    
    dcmi_type = RDF::Vocabulary.new( "http://purl.org/dc/dcmitype/")      
    prel = RDF::Vocabulary.new(Util.canonicalize("/schema/"))
    owltime = RDF::Vocabulary.new("http://purl.org/NET/c4dm/timeline.owl#")
    skos = RDF::Vocabulary.new("http://www.w3.org/2004/02/skos/core#")
    
    add_property( RDF.type, RDF::URI.new( Util.canonicalize("/schema/#{@fields["type"]}") ) )
    add_property( RDF.type, dcmi_type.MovingImage )
    add_literal( RDF::Vocab::DC.identifier, "identifier" )
    add_literal( RDF::Vocab::DC.identifier, "numeric_id")
    add_literal( RDF::Vocab::DC.title, "title" )
    add_literal( RDF::Vocab::DC.description, "description" )
    add_literal( prel.shotlist, "shotlist")
    #TODO always just a year?    
    if @fields["date"]
      add_property( RDF::Vocab::DC.issued, RDF::Literal.new( @fields["date"], :datatype => RDF::Vocab::XSD.year ) )
    end
    
    if @fields["creator"] && @fields["creator"] != "Unknown"
      creator = RDF::URI.new( Util.canonicalize( "/organization/#{Util.slug( @fields["creator"] )}") )
      add_property( RDF::Vocab::FOAF.maker, creator )
      add_statement( creator, RDF.type, RDF::Vocab::FOAF.Organization )
      add_statement( creator, RDF::Vocab::FOAF.name, @fields["creator"] )
      add_statement( creator, RDF::Vocab::FOAF.made, @uri )
    end
    
    if @fields["sponsor"]
      sponsor = RDF::URI.new( Util.canonicalize( "/organization/#{Util.slug( @fields["sponsor"] )}" ) )
      add_property( prel.sponsor, sponsor )
      add_statement( sponsor, RDF.type, RDF::Vocab::FOAF.Organization )
      add_statement( sponsor, RDF::Vocab::FOAF.name, @fields["sponsor"] )
      add_statement( sponsor, prel.sponsored, @uri )
    end    
    
    if @fields["runtime"]
      add_property(owltime.duration, RDF::Literal.new( @fields["runtime"], :datatype => RDF::Vocab::XSD.duration ) )
    end
    
    if @fields["subject"]
      @fields["subject"].each do |subject|        
        scheme = RDF::URI.new( Util.canonicalize( "/subject" ) )
        subject_uri = RDF::URI.new( Util.canonicalize("/subject/#{Util.slug(subject)}") )
        add_property( RDF::Vocab::DC.subject , subject_uri )
        add_statement( subject_uri, RDF.type, skos.Concept )
        add_statement( subject_uri, skos.inScheme, scheme )
        add_statement( subject_uri, skos.prefLabel, RDF::Literal.new(subject) )
      end
    end

    #color
    if @fields["color"]
      if @fields["color"].class == String
        colour = RDF::URI.new( Util.canonicalize( "/format/#{ @fields["color"].downcase }" ))
        add_property( prel.colour, colour )       
        add_statement( colour, RDF::RDFS.label, @fields["color"].capitalize )
        add_statement( colour, RDF.type, prel.ColourFormat )
        
      else
        @fields["color"].each do |c|
          colour = RDF::URI.new( Util.canonicalize("/format/#{ c.downcase }") )
          add_property( prel.colour, colour )
          add_statement( colour, RDF::RDFS.label, c.capitalize )
          add_statement( colour, RDF.type, prel.ColourFormat )
        end
      end
    end
    
    #sound
    if @fields["sound"]
      sound = RDF::URI.new( Util.canonicalize("/format/#{ @fields["sound"].downcase }") )
      add_property( prel.sound, sound )
      add_statement( sound , RDF::RDFS.label, @fields["sound"].capitalize )
      add_statement( sound, RDF.type, prel.SoundFormat )
    end
    
    #FIXME country
    #if @fields["country"]
    #end
    
  end
   
end