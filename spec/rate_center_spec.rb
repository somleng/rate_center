require "spec_helper"

module RateCenter
  RSpec.describe RateCenter do
    it "returns all rate centers" do
      ::RateCenter.load(:rate_centers, only: { us: { ny: "NWYRCYZN01", ca: "LSAN DA 01" } })

      rate_centers = RateCenter.all

      expect(rate_centers.size).to eq(2)
      nwyrcyzn01 = rate_centers.first

      expect(nwyrcyzn01).to have_attributes(
        country: "US",
        region: "NY",
        name: "NWYRCYZN01",
        closest_city: have_attributes(
          name: "Manhattan",
          distance_km: be_a(Float)
        )
      )
    end

    it "finds a rate center" do
      ::RateCenter.load(:rate_centers, only: { us: { ny: "NWYRCYZN01" } })

      rate_center = RateCenter.find_by!(country: "US", region: "NY", name: "NWYRCYZN01")

      expect(rate_center).to have_attributes(
        country: "US",
        region: "NY",
        name: "NWYRCYZN01"
      )
    end

    it "raises an error if the rate center can't be found" do
      ::RateCenter.load(:rate_centers, only: { us: { ny: "NWYRCYZN01" } })

      expect { RateCenter.find_by!(country: "US", region: "NY", name: "does-not-exist") }.to raise_error(Errors::NotFoundError)
    end

    it "raises an error if trying to access without first loading data" do
      ::RateCenter.unload

      expect { RateCenter.all }.to raise_error(Errors::DataNotLoadedError)
    end
  end
end
