# frozen_string_literal: true

module RASN1
  module Types
    # ASN.1 ANY: accepts any types
    #
    # If `any#value` is `nil` and Any object is not {#optional?}, `any` will be encoded as a {Null} object.
    # @author Sylvain Daubert
    class Any < Base
      # @return [String] DER-formated string
      def to_der
        case @value
        when Base, Model
          @value.to_der
        when nil
          optional? ? '' : Null.new.to_der
        else
          @value.to_s
        end
      end

      # Parse a DER string. This method updates object: {#value} will be a DER
      # string.
      # @param [String] der DER string
      # @param [Boolean] ber if +true+, accept BER encoding
      # @return [Integer] total number of parsed bytes
      def parse!(der, ber: false)
        if der.nil? || der.empty?
          return 0 if optional?

          raise ASN1Error, 'Expected ANY but get nothing'
        end

        id_size = Types.decode_identifier_octets(der).last
        total_length, = get_data(der[id_size..-1], ber)
        total_length += id_size

        @value = der[0, total_length]

        total_length
      end

      def inspect(level=0)
        lvl = level >= 0 ? level : 0
        str = '  ' * lvl
        str << "#{@name} " unless @name.nil?
        str << if @value.nil?
                 '(ANY) NULL'
               elsif @value.is_a?(OctetString) || @value.is_a?(BitString)
                 "(ANY) #{@value.type}: #{value.value.inspect}"
               elsif @value.class < Base
                 "(ANY) #{@value.type}: #{value.value}"
               else
                 "ANY: #{value.to_s.inspect}"
               end
      end
    end
  end
end
