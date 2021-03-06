# frozen_string_literal: true

module RASN1
  module Types
    # ASN.1 Bit String
    # @author Sylvain Daubert
    class BitString < Primitive
      # BitString id value
      ID = 3

      # @param [Integer] bit_length
      # @return [Integer]
      attr_writer :bit_length

      # @overload initialize(options={})
      #   @param [Hash] options
      #   @option options [Object] :bit_length default bit_length value. Should be
      #     present if +:default+ is set
      # @overload initialize(value, options={})
      #   @param [Object] value value to set for this ASN.1 object
      #   @param [Hash] options
      #   @option options [Object] :bit_length default bit_length value. Should be
      #     present if +:default+ is set
      # @see Base#initialize common options to all ASN.1 types
      def initialize(value_or_options={}, options={})
        super
        if @default
          raise ASN1Error, "#{@name}: default bit length is not defined" if @options[:bit_length].nil?

          @default_bit_length = @options[:bit_length]
        end
        @bit_length = @options[:bit_length]
      end

      # Get bit length
      def bit_length
        if @value.nil?
          @default_bit_length
        else
          @bit_length
        end
      end

      # @param [Integer] level
      # @return [String]
      def inspect(level=0)
        str = common_inspect(level)
        str << " #{value.inspect} (bit length: #{bit_length})"
      end

      private

      def can_build?
        !(!@default.nil? && (@value.nil? || (@value == @default) &&
                              (@bit_length == @default_bit_length))) &&
          !(optional? && @value.nil?)
      end

      def value_to_der
        raise ASN1Error, "#{@name}: bit length is not set" if bit_length.nil?

        value = @value || ''
        value << "\x00" while value.length * 8 < @bit_length.to_i
        value.force_encoding('BINARY')

        if value.length * 8 > @bit_length.to_i
          max_len = @bit_length.to_i / 8 + ((@bit_length.to_i % 8).positive? ? 1 : 0)
          value = value[0, max_len].to_s
        end

        unused = value.length * 8 - @bit_length.to_i
        der = [unused, value].pack('CA*')

        if unused.positive?
          last_byte = value[-1].to_s.unpack1('C').to_i
          last_byte &= (0xff >> unused) << unused
          der[-1] = [last_byte].pack('C')
        end

        @value = value

        der
      end

      def der_to_value(der, ber: false)
        unused = der.unpack1('C').to_i
        value = der[1..-1].to_s
        @bit_length = value.length * 8 - unused
        @value = value
      end
    end
  end
end
