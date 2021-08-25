class SubdomainValidator
  def self.visit_http_or_https(subdomain)
    results = []

    protocols = ['http://', 'https://']

    visit_thread = protocols.map do |protocol|
      Thread.new do
        begin
          domain_to_visit = '%s%s' % [protocol, subdomain]

          uri = URI(domain_to_visit)

          req = Net::HTTP::Get.new uri
          res = Net::HTTP.start(uri.host, uri.port, :read_timeout => 1) {|http| http.request(req)}

          redirect_to = res['Location'] || ''

          if redirect_to[-1] == '/'
            redirect_to = redirect_to[0...redirect_to.length-1]
          end

          if redirect_to.include? subdomain
            results.push redirect_to
          else
            results.push domain_to_visit || redirect_to
          end
        rescue => e
          next
        end
      end
    end

    visit_thread.map(&:join)

    results
  end
end
