require "spec_helper"
require "rate_center/data_source/simple_maps"

module RateCenter
  module DataSource
    RSpec.describe SimpleMaps do
      it "loads data" do
        skip("Don't load data on CI") if ENV["CI"]

        data_source = SimpleMaps.new

        data_source.load_data!(
          data_directory: Pathname(File.expand_path("../../tmp/cities", __dir__))
        )
      end
    end
  end
end
