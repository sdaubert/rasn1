# frozen_string_literal: true

require_relative '../spec_helper'

# rubocop:disable Metrics/BlockLength
module RASN1::Types # rubocop:disable Metrics/ModuleLength
  describe Integer do
    let(:hsh) { { one: 1, two: 2 } }

    describe '.type' do
      it 'gets ASN.1 type' do
        expect(Integer.type).to eq('INTEGER')
      end
    end

    describe '#initialize' do
      it 'creates an Integer with default values' do
        int = Integer.new
        expect(int).to be_primitive
        expect(int).to_not be_optional
        expect(int.asn1_class).to eq(:universal)
        expect(int.default).to eq(nil)
      end

      it 'accepts an :enum key' do
        int = Integer.new(enum: hsh)
        expect(int.enum).to eq(hsh)

        int.value = 1
        expect(int.value).to eq(:one)
        int.value = :two
        expect(int.value).to eq(:two)
      end

      it 'raises when default value is not in enum' do
        expect { Integer.new(default: :three, enum: hsh) }
          .to raise_error(RASN1::EnumeratedError, /default value/)
        expect { Integer.new(default: 3, enum: hsh) }
          .to raise_error(RASN1::EnumeratedError, /default value/)
        expect { Integer.new(default: Object.new, enum: hsh) }
          .to raise_error(TypeError, /default value/)
      end
    end

    describe '#to_i' do
      it 'gets ruby Integer object' do
        int = Integer.new(value: 53)
        expect(int.to_i).to eq(53)
      end

      it 'gets default value is one is defined and not value was set' do
        int = Integer.new(default: 123_456)
        expect(int.to_i).to eq(123_456)
        int.value = 12
        expect(int.to_i).to eq(12)
      end

      it 'returns 0 if no default value nor value were set' do
        expect(Integer.new.to_i).to eq(0)
      end

      it 'returns integer even when was build with an :enum key' do
        expect(Integer.new(enum: hsh).to_i).to eq(0)
        expect(Integer.new(value: :one, enum: hsh).to_i).to eq(1)
      end
    end

    describe '#to_der' do
      it 'generates a DER string' do
        int = Integer.new
        int.value = 42
        expect(int.to_der).to eq("\x02\x01\x2a".b)
        int.value = 65_536
        expect(int.to_der).to eq("\x02\x03\x01\x00\x00".b)
        int.value = 255
        expect(int.to_der).to eq("\x02\x02\x00\xff".b)
        int.value = -1
        expect(int.to_der).to eq("\x02\x01\xff".b)
        int.value = -543_210
        expect(int.to_der).to eq("\x02\x03\xf7\xb6\x16".b)
      end

      it 'generates a DER string with enum' do
        int = Integer.new(value: :two, enum: hsh)
        expect(int.to_der).to eq("\x02\x01\x02".b)
      end

      it 'generates a DER string according to ASN.1 class' do
        int = Integer.new(class: :application)
        int.value = 16
        expect(int.to_der).to eq("\x42\x01\x10".b)
      end

      it 'generates a DER string according to default' do
        int = Integer.new(default: 545)
        int.value = 545
        expect(int.to_der).to eq('')
        int.value = 65_000
        expect(int.to_der).to eq("\x02\x03\x00\xfd\xe8".b)
      end

      it 'generates a DER string according to optional' do
        int = Integer.new(optional: true)
        int.value = nil
        expect(int.to_der).to eq('')
        int.value = 545
        expect(int.to_der).to eq("\x02\x02\x02\x21".b)
      end

      it 'generates a DER string with named explicit tagged type' do
        int = Integer.new(name: 'int', explicit: 3, value: 5)
        expect(int.to_der).to eq("\x83\x03\x02\x01\x05".b)
      end

      it 'generates a DER string with named explicit tagged type and enum (bug #6)' do
        int = Integer.new(name: 'int', explicit: 3, value: :one, enum: hsh)
        expect(int.to_der).to eq("\x83\x03\x02\x01\x01".b)
      end
    end

    describe '#parse!' do
      let(:int) { Integer.new }

      it 'parses a DER INTEGER string' do
        int.parse!("\x02\x01\x00".b)
        expect(int.value).to eq(0)
        int.parse!("\x02\x02\x00\xff".b)
        expect(int.value).to eq(255)
        int.parse!("\x02\x03\x01\x00\x00".b)
        expect(int.value).to eq(65_536)
        int.parse!("\x02\x01\xFF".b)
        expect(int.value).to eq(-1)
        int.parse!("\x02\x03\xf7\xb6\x16".b)
        expect(int.value).to eq(-543_210)
      end

      it 'parses a DER string for named explicit tagged integer with enum (bug #6)' do
        int = Integer.new(name: 'int', explicit: 3, enum: hsh)
        expect { int.parse!("\x83\x03\x02\x01\x01".b) }.to_not raise_error
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
