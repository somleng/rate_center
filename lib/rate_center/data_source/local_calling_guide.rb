require "faraday"
require "multi_xml"
require "rack"
require "yaml"
require "countries"

module RateCenter
  module DataSource
    class LocalCallingGuide
      class Error < StandardError; end

      attr_reader :client, :data_directory

      def initialize(**options)
        @client = options.fetch(:client) { Client.new }
      end

      class ResponseParser
        Response = Struct.new(:rate_centers, keyword_init: true)

        attr_reader :parser

        def initialize(**options)
          @parser = options.fetch(:parser) { MultiXml }
        end

        def parse(xml)
          data = parser.parse(xml)
          rc_data = data.dig("root", "rcdata")

          return Response.new(rate_centers: []) if rc_data.nil?

          rc_data = rc_data.is_a?(Array) ? rc_data : Array([ rc_data ])
          rate_centers = rc_data.map do |d|
            OpenStruct.new(d.transform_values { |v| v.strip unless v.strip.empty? })
          end

          Response.new(rate_centers: rate_centers)
        end
      end

      class Client
        HOST = "https://localcallingguide.com/".freeze

        attr_reader :host, :http_client, :response_parser

        def initialize(**options)
          @host = options.fetch(:host, HOST)
          @http_client = options.fetch(:http_client) { default_http_client }
          @response_parser =  options.fetch(:response_parser) { ResponseParser.new }
        end

        def fetch_rate_center_data(params)
          uri = URI("/xmlrc.php")
          uri.query = Rack::Utils.build_query(params)
          response = http_client.get(uri)
          response_parser.parse(response.body)
        end

        private

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

        us_regions = Array(options.fetch(:regions) { regions_for("US") })
        us_regions = us_regions.first(options.fetch(:limit).to_i) if options.key?(:limit)

        Array(us_regions).each do |region, _|
          region_identifier = region.downcase
          data_file = data_directory.join("#{region_identifier}.yml")

          next if data_file.exist? && !options.fetch(:override, false)

          rate_centers = client.fetch_rate_center_data(region:).rate_centers
          next if rate_centers.empty?

          data = rate_centers.sort_by(&:rc).map do |rate_center|
            raise Error.new("State mismatch. Expected #{rate_center.region} to eq #{region}") unless rate_center.region.upcase == region

            {
              "region" => region,
              "exchange" => rate_center.exch,
              "name" => rate_center.rc,
              "short_name" => rate_center.rcshort,
              "lata" => rate_center.lata,
              "ilec_name" => rate_center.ilec_name,
              "lat" => rate_center.rc_lat,
              "long" => rate_center.rc_lon
            }
          end

          data_file.write(
            {
              "rate_centers" => {
                "us" => {
                  region_identifier => data
                }
              }
            }.to_yaml
          )
        end
      end

      private

      def regions_for(country_code)
        ISO3166::Country.new(country_code).subdivisions
      end
    end
  end
end
