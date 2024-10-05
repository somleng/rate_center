require "spec_helper"

module RateCenter
  RSpec.describe DataLoader do
    it "loads all data" do
      data_loader = DataLoader.new

      data_loader.load(:all)
    end

    it "loads all cities" do
      data_loader = DataLoader.new

      data_loader.load(:cities, :all)
    end

    it "supports filtering by country" do
      data_loader = DataLoader.new

      result = data_loader.load(:cities, only: :us)

      expect(result.map(&:country).uniq).to eq([ "US" ])
    end

    it "supports filtering by region" do
      data_loader = DataLoader.new

      result = data_loader.load(:cities, only: { us: :ny })

      expect(result.map(&:region).uniq).to eq([ "NY" ])
    end

    it "supports filtering specific cities" do
      data_loader = DataLoader.new

      results = data_loader.load(:cities, only: { us: { ny: "New York" } })

      expect(results.size).to eq(1)
      expect(results.first).to have_attributes(
        country: "US",
        region: "NY",
        name: "New York"
      )
    end

    xit "supports filtering specific rate centers"
  end
end
