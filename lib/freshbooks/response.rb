module FreshBooks
  class Response
    attr_accessor :doc
    attr_reader   :raw_response
    
    def initialize(xml_raw)
      @raw_response = xml_raw
      @doc = REXML::Document.new(xml_raw)
    end
    
    def elements
      @doc.root.elements
    end
    
    def success?
      @doc.root.attributes['status'] == 'ok'
    end
    
    def fail?
      !success?
    end
    
    def error_msg
      return @doc.root.elements['error'].text
    end
  end
end
