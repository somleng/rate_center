require "spec_helper"

module RateCenter
  RSpec.describe DataLoader do
    it "loads all data" do
      data_loader = DataLoader.new

      data_loader.load(:all)

      expect(data_loader.cities.size).to be_positive
      expect(data_loader.rate_centers.size).to be_positive
    end

    it "loads all cities" do
      data_loader = DataLoader.new

      data_loader.load(:cities, :all)

      expect(data_loader.cities.size).to be_positive
    end

    it "supports filtering cities by country" do
      data_loader = DataLoader.new

      data_loader.load(:cities, only: :us)

      expect(data_loader.cities.map { |data| data.fetch("country") }.uniq).to eq([ "US" ])
    end

    it "supports filtering cities by region" do
      data_loader = DataLoader.new

      data_loader.load(:cities, only: { us: :ny })

      expect(data_loader.cities.map { |data| data.fetch("region") }.uniq).to eq([ "NY" ])
    end

    it "supports filtering specific cities" do
      data_loader = DataLoader.new

      data_loader.load(:cities, only: { us: { ny: "New York" } })

      expect(data_loader.cities.size).to eq(1)
      expect(data_loader.cities.first).to include(
        "country" => "US",
        "region" => "NY",
        "name" => "New York"
      )
    end

    it "handles reloading" do
      data_loader = DataLoader.new

      data_loader.load(:cities, only: { us: { ny: "New York" } })
      expect(data_loader.cities.size).to eq(1)

      data_loader.load(:cities, only: { us: [ :ny ] })
      expect(data_loader.cities.size).to be > 1
    end

    it "loads all rate centers" do
      data_loader = DataLoader.new

      data_loader.load(:rate_centers, :all)

      expect(data_loader.rate_centers.size).to be_positive
    end

    it "supports filtering rate centers by country" do
      data_loader = DataLoader.new

      data_loader.load(:rate_centers, only: :us)

      expect(data_loader.rate_centers.map { |data| data.fetch("country") }.uniq).to eq([ "US" ])
    end

    it "supports filtering rate centers by region" do
      data_loader = DataLoader.new

      data_loader.load(:rate_centers, only: { us: [ :ny, :ca ] })

      expect(data_loader.rate_centers.map { |data| data.fetch("region") }.uniq).to contain_exactly("NY", "CA")
    end

    it "supports filtering specific rate centers" do
      data_loader = DataLoader.new

      data_loader.load(:rate_centers, only: { us: { ny: "NWYRCYZN01", ca: "LSAN DA 01" } })

      expect(data_loader.rate_centers.size).to eq(2)

      expect(data_loader.rate_centers[0]).to include(
        "country" => "US",
        "region" => "NY",
        "name" => "NWYRCYZN01"
      )

      expect(data_loader.rate_centers[1]).to include(
        "country" => "US",
        "region" => "CA",
        "name" => "LSAN DA 01"
      )
    end
  end
end
