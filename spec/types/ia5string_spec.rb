# coding: utf-8
require_relative '../spec_helper'

module RASN1::Types

  describe IA5String do
    describe '.type' do
      it 'gets ASN.1 type' do
        expect(IA5String.type).to eq('IA5String')
      end
    end

    describe '#initialize' do
      it 'creates a IA5String with default values' do
        ia5 = IA5String.new
        expect(ia5).to be_primitive
        expect(ia5).to_not be_optional
        expect(ia5.asn1_class).to eq(:universal)
        expect(ia5.default).to eq(nil)
      end
    end
    
    describe '#to_der' do
      it 'generates a DER string' do
        ia5 = IA5String.new
        ia5.value = 'azerty,;:'
        expect(ia5.to_der).to eq(binary("\x16\x09azerty,;:"))
      end

      it 'generates a DER string according to ASN.1 class' do
        ia5 = IA5String.new(class: :context)
        ia5.value = 'a'
        expect(ia5.to_der).to eq(binary("\x96\x01a"))
      end

      it 'generates a DER string according to default' do
        ia5 = IA5String.new(default: 'NOP', octet_length: 22)
        ia5.value = 'NOP'
        expect(ia5.to_der).to eq('')
        ia5.value = 'N'
        expect(ia5.to_der).to eq(binary("\x16\x01N"))
      end

      it 'generates a DER string according to optional' do
        ia5 = IA5String.new(optional: true)
        ia5.value = nil
        expect(ia5.to_der).to eq('')
        ia5.value = 'abc'
        expect(ia5.to_der).to eq(binary("\x16\x03abc"))
      end
    end

    describe '#parse!' do
      let(:ia5) { IA5String.new }

      it 'parses a DER IA5STRING' do
        ia5.parse!(binary("\x16\x04!:;,"))
        expect(ia5.value).to eq('!:;,')
      end
    end
  end
end
