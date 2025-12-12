# frozen_string_literal: true

module Aven
  module Agentic
    module Tools
      module Concerns
        module GeoFiltering
          extend ActiveSupport::Concern

          class_methods do
            # Define geo search parameters
            def geo_searchable(lat_column: :latitude, lng_column: :longitude)
              @geo_config = {
                lat_column:,
                lng_column:
              }

              param :latitude, type: :number, desc: "Latitude for geo search"
              param :longitude, type: :number, desc: "Longitude for geo search"
              param :radius_km, type: :number, desc: "Search radius in kilometers", required: false
            end

            def geo_config
              @geo_config || {}
            end
          end

          # Apply geo filtering to a scope
          def apply_geo_filter(scope, lat:, lng:, radius_km: 50)
            return scope if lat.blank? || lng.blank?

            config = self.class.geo_config
            lat_col = config[:lat_column]
            lng_col = config[:lng_column]

            # Haversine distance formula in SQL
            distance_sql = <<~SQL.squish
              (6371 * acos(
                cos(radians(?)) *
                cos(radians(#{lat_col})) *
                cos(radians(#{lng_col}) - radians(?)) +
                sin(radians(?)) *
                sin(radians(#{lat_col}))
              ))
            SQL

            scope
              .where("#{lat_col} IS NOT NULL AND #{lng_col} IS NOT NULL")
              .where("#{distance_sql} <= ?", lat, lng, lat, radius_km)
              .order(Arel.sql("#{distance_sql} ASC").gsub("?", lat.to_s).gsub("?", lng.to_s))
          end
        end
      end
    end
  end
end
