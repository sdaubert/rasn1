# frozen_string_literal: true

module RASN1
  module Types
    # ASN.1 Null
    # @author Sylvain Daubert
    class Null < Primitive
      # Null id value
      ID = 0x05

      def void_value
        ''
      end

      # @return [String]
      def inspect(level=0)
        str = common_inspect(level, trailing_space: false)[0..-2] # remove terminal ':'
        str << ' OPTIONAL' if optional?
        str
      end

      private

      def value_to_der
        ''
      end

      # rubocop:disable Lint/UnusedMethodArgument
      def der_to_value(der, ber: false)
        raise ASN1Error, 'NULL should not have content!' if der.length.positive?

        @value = nil
      end
      # rubocop:enable Lint/UnusedMethodArgument
    end
  end
end
