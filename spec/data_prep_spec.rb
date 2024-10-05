require "spec_helper"
require "rate_center/data_prep"

module RateCenter
  RSpec.describe DataPrep do
    it "prepares data" do
      skip("Don't load data on CI") if ENV["CI"]

      data_prep = DataPrep.new(data_directory: Pathname(File.expand_path("../tmp/", __dir__)))

      data_prep.call
    end
  end
end
