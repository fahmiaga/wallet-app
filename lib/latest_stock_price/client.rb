require "net/http"
require "json"
require_relative "version"

module LatestStockPrice
  class Client
    BASE_URL = "https://latest-stock-price.p.rapidapi.com"
    def initialize(api_key: "e1241a3affmshe72cd11cc356253p173c9djsn035a550e4fa2", host: "latest-stock-price.p.rapidapi.com")
      @api_key = api_key or raise "RAPIDAPI_KEY missing"
      @host = host
    end

    def price(symbol)
      all = price_all
      all.find { |stock| stock["symbol"].casecmp?(symbol) }
    end

    def prices(symbols)
      all = price_all
      all.select { |stock| symbols.include?(stock["symbol"]) }
    end

    def price_all
      get("/any")
    end

    private

    def get(path, params = {})
      uri = URI("#{BASE_URL}#{path}")
      uri.query = URI.encode_www_form(params) if params.any?
      req = Net::HTTP::Get.new(uri)
      req["X-RapidAPI-Key"] = @api_key
      req["X-RapidAPI-Host"] = @host
      Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
        res = http.request(req)
        raise "HTTP #{res.code}: #{res.body}" unless res.is_a?(Net::HTTPSuccess)
        JSON.parse(res.body)
      end
    end
  end
end
