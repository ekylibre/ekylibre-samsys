# frozen_string_literal: true

module Samsys
  module Data
    class Clusters
      class << self
        def result
          call_api
        end

        private

          def call_api
            ::Samsys::SamsysIntegration.fetch_clusters.execute do |c|
              c.success do |cluster|
                cluster
              end
            end
          end

      end
    end
  end
end
