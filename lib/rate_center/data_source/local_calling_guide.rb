require "faraday"
require "multi_xml"
require "rack"
require "json"
require "countries"
require "ostruct"

module RateCenter
  module DataSource
    class LocalCallingGuide
      SPECIAL_CASE_LATAS = [
        OpenStruct.new(code: "45010", region: "GA", country: "US")
      ].freeze

      attr_reader :client, :data_directory

      def initialize(**options)
        @client = options.fetch(:client) { Client.new }
      end

      class ResponseParser
        Response = Struct.new(:data, keyword_init: true)
        class ParseError < StandardError; end

        attr_reader :parser

        def initialize(**options)
          @parser = options.fetch(:parser) { MultiXml }
        end

        def parse(xml, keys:)
          response_data = parser.parse(xml)
          data = response_data.dig("root", *Array(keys))

          return Response.new(data: []) if data.nil?

          data = data.is_a?(Array) ? data : Array([ data ])
          parsed_data = data.map do |d|
            OpenStruct.new(d.transform_values { |v| v.strip.empty? ? nil : v })
          end

          Response.new(data: parsed_data)
        rescue MultiXml::ParseError => e
          raise ParseError.new(e.message)
        end
      end

      class Client
        HOST = "https://localcallingguide.com/".freeze

        attr_reader :host, :http_client, :response_parser

        def initialize(**options)
          @host = options.fetch(:host, HOST)
          @http_client = options.fetch(:http_client) { default_http_client }
          @response_parser = options.fetch(:response_parser) { ResponseParser.new }
        end

        def fetch_rate_center_data(params)
          response = fetch_xml(url: "/xmlrc.php", params:)
          response_parser.parse(response.body, keys: "rcdata")
        end

        private

        def fetch_xml(url:, params:)
          uri = URI(url)
          uri.query = Rack::Utils.build_query(params)
          http_client.get(uri)
        end

        def default_http_client
          Faraday.new(url: host) do |builder|
            builder.headers["Accept"] = "application/xml"
            builder.headers["Content-Type"] = "application/xml"

            builder.response :raise_error
          end
        end
      end

      def load_data!(**options)
        data_directory = options.fetch(:data_directory)
        FileUtils.mkdir_p(data_directory)
        ::RateCenter.load(:lata, :all)

        us_regions = Array(regions_for("US"))

        Array(us_regions).each do |region, _|
          data_file = data_directory.join("#{region.downcase}.json")

          rate_centers = fetch_rate_centers_for(region)
          SPECIAL_CASE_LATAS.select { |lata| lata.region == region }.each do |lata|
            rate_centers.concat(client.fetch_rate_center_data(region:, lata: lata.code).data)
          end
          next if rate_centers.empty?

          data = rate_centers.sort_by { |rc| [ (rc.rcshort || rc.rc), rc.exch ] }.map do |rate_center|
            related_rate_center = rate_centers.find { |rc| rc.exch == rate_center.see_exch } unless rate_center.see_exch.nil?

            {
              "country" => "US",
              "region" => region,
              "exchange" => rate_center.exch,
              "name" => (rate_center.rcshort || rate_center.rc).strip.upcase,
              "full_name" => rate_center.rc,
              "lata" => rate_center.lata.slice(0, 3),
              "ilec_name" => rate_center.ilec_name,
              "lat" => rate_center.rc_lat || related_rate_center&.rc_lat,
              "long" => rate_center.rc_lon || related_rate_center&.rc_lon
            }
          end

          data_file.write(JSON.pretty_generate("rate_centers" => data))
        end
      end

      private

      def regions_for(country_code)
        ISO3166::Country.new(country_code).subdivisions
      end

      def lata_codes_for(country_code, region)
        ::RateCenter::Lata.where(country: country_code, region: region)
      end

      def fetch_rate_centers_for(region)
        client.fetch_rate_center_data(region:).data
      rescue ResponseParser::ParseError
        lata_codes = lata_codes_for("US", region)
        lata_codes.each_with_object([]) do |lata, result|
          result.concat(client.fetch_rate_center_data(region:, lata: lata.code).data)
        end
      end
    end
  end
end
