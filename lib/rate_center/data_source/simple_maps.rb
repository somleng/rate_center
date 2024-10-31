require "faraday"
require "zip"
require "csv"
require "json"
require "ostruct"

module RateCenter
  module DataSource
    class SimpleMaps
      class ResponseParser
        class City < OpenStruct
          def region_id
            self[:state_id] || self[:province_id]
          end
        end

        def parse(response, database_filename:)
          database_file = extract_zipped_file(response, filename: database_filename)

          CSV.parse(database_file.read, headers: true).each_with_object([]) do |row_data, result|
            result << City.new(row_data.to_h)
          end
        end

        private

        def extract_zipped_file(zip_data, filename:)
          Zip::InputStream.open(StringIO.new(zip_data)) do |zip_stream|
            while (entry = zip_stream.get_next_entry)
              return entry.get_input_stream if entry.name == filename
            end
          end
        end
      end

      class Client
        HOST = "https://simplemaps.com/".freeze

        DATA_FILES = {
          us: OpenStruct.new(
            path: "static/data/us-cities/1.79/basic/simplemaps_uscities_basicv1.79.zip",
            database_filename: "uscities.csv",
          ),
          ca: OpenStruct.new(
            path: "static/data/canada-cities/1.8/basic/simplemaps_canadacities_basicv1.8.zip",
            database_filename: "canadacities.csv"
          )
        }.freeze

        attr_reader :host, :http_client, :response_parser

        def initialize(**options)
          @host = options.fetch(:host, HOST)
          @http_client = options.fetch(:http_client) { default_http_client }
          @response_parser = options.fetch(:response_parser) { ResponseParser.new }
        end

        def fetch_data(**options)
          path = options.fetch(:path) { DATA_FILES.fetch(options.fetch(:country)).path }
          database_filename = options.fetch(:database_filename) { DATA_FILES.fetch(options.fetch(:country)).database_filename }
          uri = URI(path)
          response = http_client.get(uri)
          response_parser.parse(response.body, database_filename:)
        end

        private

        def default_http_client
          Faraday.new(url: host) do |builder|
            builder.response :raise_error
          end
        end
      end

      COUNTRIES = [ :us, :ca ].freeze

      attr_reader :client, :data_directory

      def initialize(**options)
        @client = options.fetch(:client) { Client.new }
      end

      def load_data!(**options)
        COUNTRIES.each do |country|
          data_directory = options.fetch(:data_directory).join(country.to_s)
          FileUtils.mkdir_p(data_directory)

          data = client.fetch_data(country:)

          cities_by_region = data.each_with_object(Hash.new { |h, k| h[k] = [] }) do |city, result|
            result[city.region_id] << city
          end

          cities_by_region.each do |region, cities|
            data_file = data_directory.join("#{region.downcase}.json")

            data = cities.sort_by { |city| [ city.city, city.county_name ] }.map do |city|
              {
                "country" => country.to_s.upcase,
                "region" => city.region_id,
                "county" => city.county_name,
                "name" => city.city,
                "lat" => city.lat,
                "long" => city.lng
              }
            end

            data_file.write(JSON.pretty_generate("cities" => data))
          end
        end
      end
    end
  end
end
