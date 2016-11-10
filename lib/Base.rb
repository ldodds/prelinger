require "libxml"
require 'rdf'
require 'rdf/vocab'
require 'Util'

class Base
  attr_reader :statements

  def initialize(data)
    parser = LibXML::XML::Parser.string(data)
    doc = parser.parse
    @root = doc.root
          
  end
  
  def add_property(predicate, object)
    add_statement( @uri, predicate, object )
  end
   
  def add_statement(subject, predicate, object)
    @statements << RDF::Statement.new( subject, predicate, object )
  end
  
  def read_tag(tagname, base=@root)
    tag = base.find_first(tagname)
    if tag != nil && tag.first && tag.first.content != nil
        return tag.first.content
    end
    #retry    
    tag = base.find_first(tagname.upcase)
    if tag != nil && tag.first && tag.first.content != nil
        return tag.first.content
    end    
    return nil    
  end
  
  
end