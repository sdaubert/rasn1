module RASN1
  module Types

    # ASN.1 sequence
    #
    # A sequence is a collection of another ASN.1 types.
    #
    # To encode this ASN.1 example:
    #  Record ::= SEQUENCE {
    #    id        INTEGER,
    #    room  [0] INTEGER OPTIONAL,
    #    house [1] IMPLICIT INTEGER DEFAULT 0
    #  }
    # do:
    #  seq = RASN1::Types::Sequence.new(:record)
    #  seq.value = [
    #               RASN1::Types::Integer(:id),
    #               RASN1::Types::Integer(:id, explicit: 0, optional: true),
    #               RASN1::Types::Integer(:id, implicit: 1, default: 0)
    #              ]
    # @author Sylvain Daubert
    class Sequence < Constructed
      TAG = 0x10

      private

      def value_to_der
        @value.map { |element| element.to_der }.join
      end

      def der_to_value(der, ber:false)
        nb_bytes = 0
        @value.each do |element|
          nb_bytes += element.parse!(der[nb_bytes..-1])
        end
      end
    end
  end
end