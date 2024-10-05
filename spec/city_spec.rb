require "spec_helper"

module RateCenter
  RSpec.describe City do
    it "returns all cities" do
      ::RateCenter.load(:cities, only: { us: { ny: "New York", ca: "Los Angeles" } })

      cities = City.all

      expect(cities.size).to eq(2)

      new_york = cities.first
      expect(new_york.nearby_rate_centers.first).to have_attributes(
        name: be_a(String),
        distance: have_attributes(
          value: be_a(Float),
          units: eq("km")
        )
      )
    end

    it "finds a city" do
      ::RateCenter.load(:cities, only: { us: { ny: "New York" } })

      city = City.find_by!(country: "US", region: "NY", name: "New York")

      expect(city).to have_attributes(
        country: "US",
        region: "NY",
        name: "New York"
      )
    end

    it "raises an error if the city can't be found" do
      ::RateCenter.load(:cities, only: { us: { ny: "New York" } })

      expect { City.find_by!(country: "US", region: "NY", name: "Los Angeles") }.to raise_error(Errors::NotFoundError)
    end

    it "raises an error if trying to access without first loading data" do
      ::RateCenter.unload

      expect { City.all }.to raise_error(Errors::DataNotLoadedError)
    end
  end
end
