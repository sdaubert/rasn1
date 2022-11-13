# coding: utf-8
# frozen_string_literal: true

require_relative '../spec_helper'

describe RASN1::Types::BmpString do # rubocop:disable Metrics/BlockLength
  describe '.type' do
    it 'gets ASN.1 type' do
      expect(described_class.type).to eq('BmpString')
    end
  end

  describe '#initialize' do
    it 'creates a subjectString with default values' do
      subject = described_class.new
      expect(subject).to be_primitive
      expect(subject).to_not be_optional
      expect(subject.asn1_class).to eq(:universal)
      expect(subject.default).to eq(nil)
    end
  end

  describe '#to_der' do # rubocop:disable Metrics/BlockLength
    it 'generates a DER string from UTF-8 input' do
      subject = described_class.new
      subject.value = (+'Α').force_encoding('UTF-8')
      expect(subject.to_der).to eq("\x1E\x02\x03\x91".b)
    end

    it 'generates a DER string from UTF-16BE input' do
      subject = described_class.new
      subject.value = (+"\x03\x91").force_encoding('UTF-16BE')
      expect(subject.to_der).to eq("\x1E\x02\x03\x91".b)
    end

    it 'generates a DER string according to ASN.1 class' do
      subject = described_class.new(class: :context)
      subject.value = 'abc'
      expect(subject.to_der).to eq("\x9E\x06\x00a\x00b\x00c".b)
    end

    it 'generates a DER string according to default' do
      subject = described_class.new(default: 'NOP')
      subject.value = 'NOP'
      expect(subject.to_der).to eq('')
      subject.value = 'N'
      expect(subject.to_der).to eq("\x1E\x02\x00N".b)
    end

    it 'generates a DER string according to optional' do
      subject = described_class.new(optional: true)
      subject.value = nil
      expect(subject.to_der).to eq('')
      subject.value = 'abc'
      expect(subject.to_der).to eq("\x1e\x06\x00a\x00b\x00c".b)
    end
  end

  describe '#parse!' do
    let(:subject) { described_class.new }

    it 'parses a DER BMPString' do
      subject.parse!("\x1e\x02\x03\x91".b)
      expect(subject.value).to eq((+"\x03\x91").force_encoding('UTF-16BE'))
      expect(subject.value.encoding).to eq(Encoding::UTF_16BE)
    end
  end
end
