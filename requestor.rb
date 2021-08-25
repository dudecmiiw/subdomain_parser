require 'net/http'

class Requestor
  class << self
    def do_get(uri)
      uri = URI(uri)
      Net::HTTP.get_response(uri).body
    end

    def do_post(uri, body)
      uri = URI(uri)
      Net::HTTP.post_form(uri, body).body
    end
  end
end
