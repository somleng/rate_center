module RateCenter
  class Lata < OpenStruct
    extend Collection

    class << self
      private

      def data
        ::RateCenter.data_loader.lata
      end

      def load_collection
        data.map { |data| new(**data) }
      end
    end
  end
end
