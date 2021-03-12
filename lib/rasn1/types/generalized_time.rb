# frozen_string_literal: true

module RASN1
  module Types
    # ASN.1 GeneralizedTime
    #
    # +{#value} of a {GeneralizedTime} should be a ruby Time.
    #
    # ===Notes
    # When encoding, resulting string is always a UTC time, appended with +Z+.
    # Minutes and seconds are always generated. Fractions of second are generated
    # if value Time object have them.
    #
    # On parsing, are supported:
    # * UTC times (ending with +Z+),
    # * local times (no suffix),
    # * local times with difference between UTC and this local time (ending with
    #   +sHHMM+, where +s+ is +++ or +-+, and +HHMM+ is the time differential
    #   betwen UTC and local time).
    # These times may include minutes and seconds. Fractions of hour, minute and
    # second are supported.
    # @author Sylvain Daubert
    class GeneralizedTime < Primitive
      # GeneralizedTime id value
      ID = 24

      # Get ASN.1 type
      # @return [String]
      def self.type
        'GeneralizedTime'
      end

      def void_value
        Time.new
      end

      private

      def value_to_der
        if @value.nsec.positive?
          der = @value.getutc.strftime('%Y%m%d%H%M%S.%9NZ')
          der.sub(/0+Z/, 'Z')
        else
          @value.getutc.strftime('%Y%m%d%H%M%SZ')
        end
      end

      # rubocop:disable Lint/UnusedMethodArgument
      def der_to_value(der, ber: false)
        date_hour, fraction = der.split('.')
        date_hour = date_hour.to_s
        fraction = fraction.to_s

        utc_offset_forced = fix_date_hour_and_fraction(date_hour, fraction)
        format, frac_base = get_format(date_hour, der)

        @value = DateTime.strptime(date_hour, format).to_time
        # local time format.
        # Check DST. There may be a shift of one hour...
        fix_dst if utc_offset_forced
        @value += ".#{fraction}".to_r * frac_base unless fraction.nil?
      end
      # rubocop:enable Lint/UnusedMethodArgument

      def fix_date_hour_and_fraction(date_hour, fraction)
        if fraction.empty?
          unless date_hour.match?(/(?:[+-]\d+|Z)$/)
            # If not UTC, have to add offset with UTC to force
            # DateTime#strptime to generate a local time. But this difference
            # may be errored because of DST.
            date_hour << Time.now.strftime('%z')
            true
          end
        elsif fraction.end_with?('Z')
          fraction.slice!(-1)
          date_hour << 'Z'
          false
        else
          match = fraction.match(/(\d+)([+-]\d+)/)
          if match
            # fraction contains fraction and timezone info. Split them
            fraction.replace(match[1])
            date_hour << match[2]
            false
          else
            # fraction only contains fraction.
            # Have to add offset with UTC to force DateTime#strptime to
            # generate a local time. But this difference may be errored
            # because of DST.
            date_hour << Time.now.strftime('%z')
            true
          end
        end
      end

      def get_format(date_hour, der)
        case date_hour.size
        when 11
          ['%Y%m%d%HZ', 60 * 60]
        when 13
          ['%Y%m%d%H%MZ', 60]
        when 15
          if date_hour[-1] == 'Z'
            ['%Y%m%d%H%M%SZ', 1]
          else
            ['%Y%m%d%H%z', 60 * 60]
          end
        when 17
          ['%Y%m%d%H%M%z', 60]
        when 19
          ['%Y%m%d%H%M%S%z', 1]
        else
          prefix = @name.nil? ? type : "tag #{@name}"
          raise ASN1Error, "#{prefix}: unrecognized format: #{der}"
        end
      end

      def fix_dst
        compare_time = Time.new(*@value.to_a[0..5].reverse)
        @value = compare_time if compare_time.utc_offset != @value.utc_offset
      end
    end
  end
end
