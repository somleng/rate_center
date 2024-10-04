require "spec_helper"
require "rate_center/data_source/local_calling_guide"

module RateCenter
  module DataSource
    RSpec.describe LocalCallingGuide do
      it "loads data" do
        data_source = LocalCallingGuide.new

        data_source.load_data!(
          data_directory: Pathname(File.expand_path("../../tmp", __dir__)),
          limit: 1,
          override: true,
          regions: "WY"
        )
      end
    end
  end
end
