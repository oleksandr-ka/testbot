class TicketsApi
  class << self
    def get(action, params, locale, cache_result = false)
      if cache_result
        request_with_cache(action, params, locale)
      else
        request_without_cache(action, params, locale)
      end
    end

    private

    def request_without_cache(action, params, locale)
      response = client.get("/#{action}.json?key=eeb1cbcd-0b8a-4024-9b65-f4219cc214db&lang=#{locale}&#{params.to_query}")
      p '===========API RESPONSE==============='
      p response.body
      p JSON.parse(response.body)
      p '===========API RESPONSE==============='
      JSON.parse(response.body).try(:[], 'response')
    end

    def request_with_cache(action, params, locale)
      cache_key = "#{action}_#{locale}_#{params.to_query.downcase}"
      result = Rails.cache.fetch(cache_key) do
        request_without_cache(action, params, locale)
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