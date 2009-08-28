module FreshBooks
  class Invoice < FreshBooks::Base
    define_schema do |s|
      s.fixnum :invoice_id, :client_id, :po_number
      s.fixnum :recurring_id, :read_only => true
      s.float :amount, :discount
      s.float :amount_outstanding, :read_only => true # Don't send in update call
      s.float :paid, :read_only => true # Don't send in update call
      s.date :date
      s.array :lines
      s.object :links, :read_only => true
      s.string :number, :organization, :status, :notes, :terms, :first_name, :last_name
      s.string :p_street1, :p_street2, :p_city, :p_state, :p_country, :p_code
    end
    def name
      "#{self.first_name} #{self.last_name}"
    end
    def email
      client = Client.get(self.client_id)
      client.email
    end
    
    actions :list, :get, :create, :update, :delete, :send_by_email, :send_by_snail_mail
  end
end
