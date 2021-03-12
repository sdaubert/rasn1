# frozen_string_literal: true

module RASN1
  module Types
    # ASN.1 Integer
    # @author Sylvain Daubert
    class Integer < Primitive
      # @return [Hash,nil]
      attr_reader :enum

      # Integer id value
      ID = 2

      # @option options [Hash] :enum enumeration hash. Keys are names, and values
      #   are integers.
      # @raise [EnumeratedError] +:default+ value is unknown when +:enum+ key is present
      # @see Base#initialize common options to all ASN.1 types
      def initialize(options={})
        @enum = options[:enum] || {}
        super
        return if @enum.empty?

        # To ensure @value has the correct type
        self.value = @value unless @no_value

        case @default
        when String, Symbol
          raise EnumeratedError, "#{@name}: unknwon enumerated default value #@{default}" unless @enum.key?(@default)
        when ::Integer
          raise EnumeratedError, "#{@name}: default value #@{default} not in enumeration" unless @enum.value?(@default)

          @default = @enum.key(@default)
        when nil
        else
          raise TypeError, "#{@name}: #{@default.class} not handled as default value"
        end
      end

      def void_value
        @enum.empty? ? 0 : @enum.keys.first
      end

      # @param [Integer,String,Symbol,nil] v
      # @return [void]
      def value=(val)
        @no_value = false
        case val
        when String, Symbol
          raise EnumeratedError, "#{@name} has no :enum" if @enum.empty?
          raise EnumeratedError, "#{@name}: unknwon enumerated value #{val}" unless @enum.key? val

          super(val)
        when ::Integer
          if @enum.empty?
            super(val)
          elsif @enum.value?(val)
            super(@enum.key(val))
          else
            raise EnumeratedError, "#{@name}: #{val} not in enumeration"
          end
        when nil
          @no_value = true
        else
          raise EnumeratedError, "#{@name}: not in enumeration"
        end
      end

      # Integer value
      # @return [Integer]
      def to_i
        if @enum.empty?
          @no_value ? @default || 0 : @value
        elsif @no_value
          @enum.key?(@default) ? @enum[@default] : @enum.values.first
        else
          @enum[@value]
        end
      end

      private

      def int_value_to_der(value)
        size, modulus = value.bit_length.divmod(8)
        size += 1 if modulus.positive?
        size = 1 if size.zero?

        comp_value = value.negative? ? two_complement(value, size) : value
        ary = comp_value.digits(256)
        # value is > 0 and its MSBit is 1. Add a 0 byte to mark it as positive
        ary << 0 if value.positive? && (value >> (size * 8 - 1) == 1)
        ary.reverse.pack('C*')
      end

      def two_complement(value, size)
        (~(-value) + 1) & ((1 << (size * 8)) - 1)
      end

      def value_to_der
        case @value
        when String, Symbol
          int_value_to_der(@enum[@value])
        when ::Integer
          int_value_to_der(@value)
        else
          raise TypeError, "#{@name}: #{@value.class} not handled"
        end
      end

      # rubocop:disable Lint/UnusedMethodArgument
      def der_to_int_value(der, ber: false)
        ary = der.unpack('C*')
        v = ary.reduce(0) { |len, b| (len << 8) | b }
        v = -((~v & ((1 << v.bit_length) - 1)) + 1) if ary[0] & 0x80 == 0x80
        v
      end
      # rubocop:enable Lint/UnusedMethodArgument

      def der_to_value(der, ber: false)
        @value = der_to_int_value(der, ber: ber)
        return if @enum.empty?

        @value = @enum.key(@value)
        raise EnumeratedError, "#{@name}: value #{v} not in enumeration" if @value.nil?
      end

      def explicit_type
        self.class.new(name: @name, enum: @enum)
      end
    end
  end
end
