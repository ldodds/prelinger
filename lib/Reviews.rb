require "libxml"
require 'rdf'
require 'Base'
require 'Util'

class Reviews < Base
  
  def initialize(film, data)
    super(data)
    
    @film = film
    @id = film.fields["identifier"]
    @uri = RDF::URI.new( Util.canonicalize("/film/#{film.fields["identifier"]}"))
      
    @reviews = []
    @root.find("review").each do |tag|
      review = {}
      ["review_id", "reviewbody", "reviewtitle", "reviewer", "reviewdate", "createdate", "stars"].each do |t|
        review[t] = read_tag(t, tag)
      end
      if review["review_id"] == nil
        #Some of the reviews are missing unique identifiers
        review["review_id"] = Util.slug( review["createdate"] )
      end
      
      @reviews << review
    end
    
    #FIXME average rating
    info = @root.find_first("info")
    if info != nil
      @average = read_tag("avg_rating", info)
    end
        
    generate_statements()
      
  end

  def generate_statements()
    @statements = []
      
    rev = RDF::Vocabulary.new( "http://purl.org/stuff/rev#" )
    prel = RDF::Vocabulary.new(Util.canonicalize("/schema/"))
      
    @reviews.each do |review|
      uri = RDF::URI.new( Util.canonicalize( "/review/#{review["review_id"]}") )
      
      add_statement( @uri, rev.hasReview, uri )
      add_statement( uri, RDF.type, rev.Review )
      add_statement( uri, rev.title, RDF::Literal.new( review["reviewtitle"] ) )
      add_statement( uri, rev.text, RDF::Literal.new( review["reviewbody"] ) )
      add_statement( uri, rev.reviewer, RDF::Literal.new( review["reviewer"] ) )
      add_statement( uri, RDF::DC.identifier, RDF::Literal.new( review["review_id"] ) )
      add_statement( uri, rev.rating, RDF::Literal.new( review["stars"], :datatype => RDF::XSD.int ) )
      created = review["reviewdate"].sub(" ", "T")
      add_statement( uri, RDF::DC.created, RDF::Literal.new( created, :datatype => RDF::XSD.dateTime ) )
      
      add_statement( uri, rev.minRating, RDF::Literal.new("1", :datatype => RDF::XSD.int))  
      add_statement( uri, rev.maxRating, RDF::Literal.new("5", :datatype => RDF::XSD.int))
    end
    add_statement( @uri, prel.averageRating, RDF::Literal.new(@average, :datatype => RDF::XSD.int) ) if @average
    
  end  
end