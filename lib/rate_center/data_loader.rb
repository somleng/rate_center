require "yaml"
require "ostruct"
require "pry"

module RateCenter
  class DataLoader
    attr_reader :data_directory, :cities, :rate_centers

    def initialize(**options)
      @data_directory = options.fetch(:data_directory) { Pathname(File.expand_path("../../data/", __dir__)) }
    end

    def load(type, ...)
      case type.to_sym
      when :all
        @cities = load_data("cities", :all)
        @rate_centers = load_data("rate_centers", :all)
      when :cities
        @cities = load_data("cities", ...)
      when :rate_centers
        @rate_centers = load_data("rate_centers", ...)
      else
        raise ArgumentError, "Invalid type: #{type}"
      end
    end

    private

    def load_data_from(files, type:)
      Array(files).each_with_object([]) do |file, result|
        YAML.load(file.read).fetch(type).each do |data|
          result << OpenStruct.new(**data)
        end
      end
    end

    def load_region_data(type:, country:, region:)
      load_data_from(
        data_directory.join(type.to_s, country.to_s.downcase, "#{region.to_s.downcase}.yml"),
        type:
      )
    end

    def load_data(type, all = nil, **options)
      directory = data_directory.join(type)

      if all
        load_data_from(directory.glob("**/*.yml"), type:)
      else
        filter = options.fetch(:only)

        unless filter.is_a?(Hash)
          return Array(filter).each_with_object([]) do |country, result|
            result.concat(
              load_data_from(
                directory.join(country.to_s.downcase).glob("**/*.yml"),
                type:
              )
            )
          end
        end

        filter.each_with_object([]) do |(country, regions), result|
          if regions.is_a?(Hash)
            regions.each do |region, keys|
              data = load_region_data(type:, country:, region:)
              result.concat(data.select { |d| Array(keys).include?(d.name) })
            end
          else
            Array(regions).each do |region|
              result.concat(load_region_data(type:, country:, region:))
            end
          end
        end
      end
    end
  end
end

# data_loader = DataLoader.new
# data_loader.load("all")
# data_loader.load("cities", "all")
# data_loader.load("cities", only: "us")
# data_loader.load("cities", only: { "us" => ["ny"] }, "ca" => ["foo"])
# data_loader.load("rate_centers", "all")
# data_loader.load("rate_centers", "us")
# data_loader.load("rate_centers", only: "us" => { "ny" => ["ny"] })
