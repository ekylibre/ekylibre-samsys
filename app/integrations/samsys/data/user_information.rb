# frozen_string_literal: true

module Samsys
  module Data
    class UserInformation
      class << self
        def result
          @formated_data ||= call_api
        end

        private

          def call_api
            ::Samsys::SamsysIntegration.fetch_user_info.execute do |c|
              c.success do |user|
                format_data(user)
              end
            end
          end

          def format_data(user)
            user.filter{ |k, _v| desired_fields.include?(k) }
          end

          def desired_fields
            %i[id email firstname lastname]
          end
      end
    end
  end
end
