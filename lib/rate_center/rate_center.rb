require "ostruct"
require_relative "collection"
require_relative "vector"
require_relative "distance"

module RateCenter
  class RateCenter < OpenStruct
    extend Collection

    class << self
      private

      def data
        ::RateCenter.data_loader.rate_centers
      end

      def load_collection
        data.map do |data|
          rate_center = new(**data)
          closest_city = data["closest_city"]
          next rate_center if closest_city.nil?

          distance = closest_city.fetch("distance")
          rate_center.closest_city = Vector.new(
            name: closest_city.fetch("name"),
            distance: Distance.new(value: distance.fetch("value"), units: distance.fetch("units"))
          )

          rate_center
        end
      end
    end
  end
end
