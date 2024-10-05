
require "ostruct"
require_relative "collection"
require_relative "vector"
require_relative "distance"

module RateCenter
  class City < OpenStruct
    extend Collection

    class << self
      private

      def data
        ::RateCenter.data_loader.cities
      end

      def load_collection
        data.map do |data|
          city = new(**data)
          city.nearby_rate_centers = Array(data["nearby_rate_centers"]).map do |rate_center|
            distance = rate_center.fetch("distance")
            Vector.new(
              name: rate_center.fetch("name"),
              distance: Distance.new(value: distance.fetch("value"), units: distance.fetch("units"))
            )
          end
          city
        end
      end
    end
  end
end
