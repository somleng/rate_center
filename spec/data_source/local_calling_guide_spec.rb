require "spec_helper"
require "rate_center/data_source/local_calling_guide"

module RateCenter
  module DataSource
    RSpec.describe LocalCallingGuide do
      it "loads data" do
        skip("Don't load data on CI") if ENV["CI"]

        data_source = LocalCallingGuide.new

        data_source.load_data!(
          data_directory: Pathname(File.expand_path("../../tmp/rate_centers/us", __dir__))
        )
      end
    end
  end
end
