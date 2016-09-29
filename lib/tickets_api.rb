class TicketsApi
  class << self
    def get(action, params, cache_result = false)
      # cache_key = "#{action}_#{params.to_query.downcase}"
      # result = Rails.cache.fetch(cache_key) do
      #   # /rail/station.json
      #   # response = self.client.get("#{action}.json?key=eeb1cbcd-0b8a-4024-9b65-f4219cc214db&lang=uk&name=#{CGI.escape(name)}")
      #   response = self.client.get("#{action}.json?key=eeb1cbcd-0b8a-4024-9b65-f4219cc214db&lang=uk&#{params.to_query}")
      #   # JSON.parse(response.body).try(:[], 'response').try(:[], 'stations')
      #   JSON.parse(response.body).try(:[], 'response')
      # end
      # Rails.cache.delete(cache_key) unless result
      # return result
      if cache_result
        request_with_cache(action, params)
      else
        request_without_cache(action, params)
      end
    end

    private

    def request_without_cache(action, params)
      p '============================='
      p "/#{action}.json?key=eeb1cbcd-0b8a-4024-9b65-f4219cc214db&lang=uk&#{params.to_query}"
      p '=============================='
      response = self.client.get("/#{action}.json?key=eeb1cbcd-0b8a-4024-9b65-f4219cc214db&lang=uk&#{params.to_query}")
      JSON.parse(response.body).try(:[], 'response')
    end

    def request_with_cache(action, params)
      cache_key = "#{action}_#{params.to_query.downcase}"
      result = Rails.cache.fetch(cache_key) do
        self.request_without_cache(action, params)
      end
      Rails.cache.delete(cache_key) unless result
      return result
    end


    def client
      url = URI.parse("https://v2.api.tickets.ua")
      http = Net::HTTP.new(url.host, url.port)
      if url.scheme == 'https'
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
      return http
    end
  end
end