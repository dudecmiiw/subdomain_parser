class String
  def to_html
    Nokogiri::HTML(self)
  end
end

class SubdomainParser
  def initialize(domain)
    @domain = domain
    @regex_patern = /\w.*#{domain}/
  end

  def parse_from(source)
    self.send('parse_from_%s' % source)
  end

  private
    def parse_from_crtsh
      uri = 'https://crt.sh/?q=%s' % [@domain]
      res = Requestor.do_get(uri)

      results = Set[]

      res.to_html.css('td:nth-child(6)').each do |td|
        child = td.children.to_s
        if child.include? '<br>'
          child = child.split('<br>')
        end

        if child.is_a? Array
          results.merge child
        else
          results.add child
        end
      end

      results
    end

    def parse_from_hacker_target
      uri = 'https://hackertarget.com/find-dns-host-records/'
      res = Requestor.do_post(uri, {
        'theinput'            => @domain,
        'thetest'             => 'hostsearch',
        'name_of_nonce_field' => 'f00679fe23',
        '_wp_http_referer'    => '/find-dns-host-records/'
      })

      res.to_html.css('#formResponse').first
         .text.scan(@regex_patern)
    end

    def parse_from_osintsh
      uri = 'https://osint.sh/subdomain/'
      res = Requestor.do_post(uri, {
        'domain' => @domain
      })

      res.to_html.css('td[data-th="Subdomain"]>a')
         .map {|link| link.text}
    end
end
