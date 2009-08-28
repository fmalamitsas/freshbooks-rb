module FreshBooks
  class Estimate < FreshBooks::Base
    define_schema do |s|
      s.string :estimate_id, :status, :notes, :terms, :first_name
      s.string :number, :last_name, :organization, :p_street1, :p_street2, :p_city
      s.string :p_state, :p_country, :p_code
      s.date :date
      s.fixnum :client_id, :po_number
      s.float :discount, :amount
      s.object :links, :read_only => true
      s.array :lines
    end
    def name
      "#{self.first_name} #{self.last_name}"
    end
    def email
      client = Client.get(self.client_id)
      client.email
    end
    
    actions :list, :get, :create, :update, :delete, :send_by_email
  end
end
