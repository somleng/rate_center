require "geocoder"
require "json"

module RateCenter
  class DataPrep
    attr_reader :data_directory, :logger

    def initialize(**options)
      @data_directory = options.fetch(:data_directory)
    end

    def call
      update_rate_centers_with_closest_city
      update_cities_with_nearby_rate_centers
      export_lata_data
    end

    private

    def update_rate_centers_with_closest_city
      rate_center_data.each do |country, region_data|
        region_data.each do |region, rate_centers|
          rate_centers.each do |rate_center|
            next if rate_center["lat"].nil? || rate_center["long"].nil?

            closest_city = find_closest(
              lat: rate_center.fetch("lat"),
              long: rate_center.fetch("long"),
              data: city_data[country][region],
              key: ->(data) { data.fetch("name") }
            ).first

            next if closest_city.nil?

            rate_center["closest_city"] = {
              "name" => closest_city.name,
              "distance_km" => closest_city.distance.round(2)
            }
          end
        end
      end

      write_data("rate_centers", rate_center_data)
    end

    def update_cities_with_nearby_rate_centers
      city_data.each do |country, region_data|
        region_data.each do |region, cities|
          candidates = Array(rate_center_data[country][region]).reject { |data| data["lat"].nil? }

          cities.each do |city|
            candidate_distances = find_closest(
              lat: city.fetch("lat"),
              long: city.fetch("long"),
              data: candidates,
              key: ->(data) { data.fetch("name") }
            )

            candidates_by_distance = candidate_distances.each_with_object(Hash.new { |h, k| h[k] = [] }) do |rate_center, result|
              result[rate_center.distance] << rate_center
            end

            nearby_rate_centers = candidates_by_distance.keys.first(3).each_with_object([]) do |distance, result|
              result.concat(candidates_by_distance.fetch(distance))
            end

            city["nearby_rate_centers"] = nearby_rate_centers.map do |rate_center|
              {
                "name" => rate_center.name,
                "distance_km" => rate_center.distance.round(2)
              }
            end
          end
        end
      end


      write_data("cities", city_data)
    end

    def export_lata_data
      lata_data = rate_center_data.each_with_object(initialize_filter) do |(country, region_data), result|
        region_data.each do |region, rate_centers|
          rate_centers.each do |rate_center|
            next if result[country][region].find { |lata| lata.fetch("code") == rate_center.fetch("lata") }

            result[country][region] << {
              "country" => rate_center.fetch("country"),
              "region" => rate_center.fetch("region"),
              "code" => rate_center.fetch("lata")
            }
          end

          result[country][region].sort_by! { |lata| lata.fetch("code") }
        end
      end

      write_data("lata", lata_data)
    end

    def find_closest(lat:, long:, data:, key:)
      distance_to = Struct.new(:name, :distance, keyword_init: true)

      distances_to = Array(data).map do |d|
        distance_to.new(
          name: key.call(d),
          distance: Geocoder::Calculations.distance_between(
            [ lat, long ],
            [ d.fetch("lat"), d.fetch("long") ],
            units: :km
          )
        )
      end

      distances_to.sort_by { |e| [ e.distance, e.name ] }
    end

    def write_data(type, data)
      data.each do |country, region_data|
        country_directory = data_directory.join(type, country.downcase)
        FileUtils.mkdir_p(country_directory)

        region_data.each do |region, data_to_write|
          region_file = country_directory.join("#{region.downcase}.json")
          region_file.write(JSON.pretty_generate(type => data_to_write))
        end
      end
    end

    def city_data
      @city_data ||= load_data("cities")
    end

    def rate_center_data
      @rate_center_data ||= load_data("rate_centers")
    end

    def load_data(type)
      data_directory.join(type).glob("**/*.json").each_with_object(Hash.new { |h, k| h[k] = {} }) do |region_file, result|
        data = JSON.parse(region_file.read)
        country = region_file.dirname.basename.to_s
        region = region_file.basename(".json").to_s
        result[country.upcase][region.upcase] = data.fetch(type.to_s)
      end
    end

    def initialize_filter
      Hash.new { |countries, country| countries[country] = Hash.new { |regions, region| regions[region] = [] } }
    end
  end
end
