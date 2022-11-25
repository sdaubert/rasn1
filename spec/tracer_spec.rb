# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable Metrics/BlockLength,Layout/ClosingParenthesisIndentation
module RASN1 # rubocop:disable Metrics/ModuleLength
  module TestTrace
    DER_SEQUENCE = "\x30\x08\x02\x01\x01\x04\x03abc".b.freeze
    TRACE_SEQUENCE = <<~ENDOFTRACE
      SEQUENCE id: 16 (0x30), len: 8 (0x08)
        INTEGER id: 2 (0x02), len: 1 (0x01)    1 (0x01)
        OCTET STRING id: 4 (0x04), len: 3 (0x03)
          0000  61 62 63                                         abc
    ENDOFTRACE

    DER_EXPLICIT_SEQUENCE = "\xa4\x0a\x30\x08\x02\x01\x01\x04\x03abc".b.freeze
    TRACE_EXPLICIT_SEQUENCE = <<~ENDOFTRACE
      EXPLICIT SEQUENCE id: 4 (0xa4), len: 10 (0x0a)
        SEQUENCE id: 16 (0x30), len: 8 (0x08)
          INTEGER id: 2 (0x02), len: 1 (0x01)    1 (0x01)
          OCTET STRING id: 4 (0x04), len: 3 (0x03)
            0000  61 62 63                                         abc
    ENDOFTRACE
  end

  describe Tracer do
    let(:io) { StringIO.new }
    subject(:tracer) { described_class.new(io) }

    it 'puts on given iostream' do
      tracer.trace('test')
      expect(io.string).to eq("test\n")
    end
  end

  describe '.trace' do
    let(:io) { StringIO.new }

    it 'traces a PRIMITIVE parsing' do
      RASN1.trace(io) do
        Types::Integer.new.parse!("\x02\x01\x01".b)
      end
      expect(io.string).to eq("INTEGER id: 2 (0x02), len: 1 (0x01)    1 (0x01)\n")
    end

    it 'traces an EXPLICIT PRIMITIVE parsing' do
      RASN1.trace(io) do
        Types::Integer.new(explicit: 8).parse!("\x88\x03\x02\x01\x01".b)
      end
      expect(io.string).to eq(<<~ENDOFTRACE
        EXPLICIT INTEGER id: 8 (0x88), len: 3 (0x03)
          0000  02 01 01                                         ...
          INTEGER id: 2 (0x02), len: 1 (0x01)    1 (0x01)
      ENDOFTRACE
      )
    end

    it 'traces an IMPLICIT PRIMITIVE parsing' do
      RASN1.trace(io) do
        Types::Integer.new(implicit: 7, class: :application).parse!("\x47\x01\x01".b)
      end
      expect(io.string).to eq(<<~ENDOFTRACE
        IMPLICIT INTEGER id: 7 (0x47), len: 1 (0x01)    1 (0x01)
      ENDOFTRACE
      )
    end

    it 'traces a ANY parsing' do
      RASN1.trace(io) do
        Types::Any.new.parse!("\x02\x01\x01".b)
      end
      expect(io.string).to eq("ANY\n  0000  02 01 01                                         ...\n")
    end

    it 'traces an OPTIONAL ANY parsing' do
      RASN1.trace(io) do
        Types::Any.new(optional: true).parse!('')
        Types::Any.new(optional: true).parse!("\x02\x01\x01".b)
      end
      expect(io.string).to eq(<<~ENDOFTRACE
        OPTIONAL ANY NONE
        OPTIONAL ANY
          0000  02 01 01                                         ...
      ENDOFTRACE
      )
    end

    it 'traces a CONSTRUCTED parsing' do
      seq = Types::Sequence.new(value: [Types::Integer.new, Types::OctetString.new])
      RASN1.trace(io) do
        seq.parse!(TestTrace::DER_SEQUENCE)
      end
      expect(io.string).to eq(TestTrace::TRACE_SEQUENCE)
    end

    it 'traces an EXPLICIT CONSTRUCTED parsing' do
      seq = Types::Sequence.new(explicit: 4, value: [Types::Integer.new, Types::OctetString.new])
      RASN1.trace(io) do
        seq.parse!(TestTrace::DER_EXPLICIT_SEQUENCE)
      end
      expect(io.string).to eq(TestTrace::TRACE_EXPLICIT_SEQUENCE)
    end

    it 'traces a CONSTRUCTED parsing containing an OPTIONAL element' do
      seq = Types::Sequence.new(value: [Types::Integer.new(optional: true), Types::OctetString.new])
      RASN1.trace(io) do
        seq.parse!("\x30\x05\x04\x03def".b)
        seq.parse!("\x30\x08\x02\x01\x01\x04\x03abc".b)
      end
      expect(io.string).to eq(<<~ENDOFTRACE
        SEQUENCE id: 16 (0x30), len: 5 (0x05)
          OPTIONAL INTEGER NONE
          OCTET STRING id: 4 (0x04), len: 3 (0x03)
            0000  64 65 66                                         def
        SEQUENCE id: 16 (0x30), len: 8 (0x08)
          OPTIONAL INTEGER id: 2 (0x02), len: 1 (0x01)    1 (0x01)
          OCTET STRING id: 4 (0x04), len: 3 (0x03)
            0000  61 62 63                                         abc
      ENDOFTRACE
      )
    end

    it 'traces a CONSTRUCTED parsing containing an DEFAULT element' do
      seq = Types::Sequence.new(name: 'seq', value: [Types::Integer.new(default: 42), Types::OctetString.new])
      RASN1.trace(io) do
        seq.parse!("\x30\x05\x04\x03def".b)
        seq.parse!("\x30\x08\x02\x01\x01\x04\x03abc".b)
      end
      expect(io.string).to eq(<<~ENDOFTRACE
        seq SEQUENCE id: 16 (0x30), len: 5 (0x05)
          INTEGER DEFAULT VALUE 42
          OCTET STRING id: 4 (0x04), len: 3 (0x03)
            0000  64 65 66                                         def
        seq SEQUENCE id: 16 (0x30), len: 8 (0x08)
          INTEGER id: 2 (0x02), len: 1 (0x01)    1 (0x01)
          OCTET STRING id: 4 (0x04), len: 3 (0x03)
            0000  61 62 63                                         abc
      ENDOFTRACE
      )
    end

    it 'traces a CHOICE parsing' do
      choice = Types::Choice.new(value: [Types::Integer.new, Types::OctetString.new])
      RASN1.trace(io) do
        choice.parse!("\x02\x01\xff".b)
        choice.parse!("\x04\x03abc".b)
      end
      expect(io.string).to eq(<<~ENDOFTRACE
        CHOICE
        INTEGER id: 2 (0x02), len: 1 (0x01)    -1 (0xff)
        CHOICE
        OCTET STRING id: 4 (0x04), len: 3 (0x03)
          0000  61 62 63                                         abc
      ENDOFTRACE
      )
    end

    it 'traces MODEL parsing' do
      model = TestModel::OfModel.new
      RASN1.trace(io) do
        model.parse!("\x30\x12\x30\x06\x02\x01\x0f\x80\x01\x02\x30\x08\x02\x01\x10\x81\x03\x02\x01\x03".b)
      end
      expect(io.string).to eq(<<~ENDOFDATA
        seqof SEQUENCE OF id: 16 (0x30), len: 18 (0x12)
          record SEQUENCE id: 16 (0x30), len: 6 (0x06)
            id INTEGER id: 2 (0x02), len: 1 (0x01)    15 (0x0f)
            room IMPLICIT OPTIONAL INTEGER id: 0 (0x80), len: 1 (0x01)    2 (0x02)
            house EXPLICIT INTEGER DEFAULT VALUE 0
          record SEQUENCE id: 16 (0x30), len: 8 (0x08)
            id INTEGER id: 2 (0x02), len: 1 (0x01)    16 (0x10)
            room IMPLICIT OPTIONAL INTEGER NONE
            house EXPLICIT INTEGER id: 1 (0x81), len: 3 (0x03)
              0000  02 01 03                                         ...
              house INTEGER id: 2 (0x02), len: 1 (0x01)    3 (0x03)
      ENDOFDATA
      )
    end

    it 'traces wrapped MODEL parsing' do
      model = ModelWithImplicitWrapper.new
      RASN1.trace(io) do
        model.parse!("\x30\x0d\xa5\x0b\x02\x01\x10\x80\x01\x07\x81\x03\x02\x01\x03")
      end
      expect(io.string).to eq(<<~ENDOFDATA
        seq SEQUENCE id: 16 (0x30), len: 13 (0x0d)
          record IMPLICIT SEQUENCE id: 5 (0xa5), len: 11 (0x0b)
            id INTEGER id: 2 (0x02), len: 1 (0x01)    16 (0x10)
            room IMPLICIT OPTIONAL INTEGER id: 0 (0x80), len: 1 (0x01)    7 (0x07)
            house EXPLICIT INTEGER id: 1 (0x81), len: 3 (0x03)
              0000  02 01 03                                         ...
              house INTEGER id: 2 (0x02), len: 1 (0x01)    3 (0x03)
      ENDOFDATA
      )
    end

    it 'traces RASN1.parse' do
      RASN1.trace(io) do
        RASN1.parse(TestTrace::DER_SEQUENCE)
      end
      expect(io.string).to eq(TestTrace::TRACE_SEQUENCE)
    end

    it 'traces RASN1.parse (explicit element)' do
      RASN1.trace(io) do
        RASN1.parse(TestTrace::DER_EXPLICIT_SEQUENCE)
      end
      expect(io.string).to eq(<<~ENDOFDATA
        BASE id: 4 (0xa4), len: 10 (0x0a)
          0000  30 08 02 01 01 04 03 61 62 63                    0......abc
      ENDOFDATA
      )
    end

    it 'traces long length' do
      os = Types::OctetString.new(value: 'a' * 256)
      RASN1.trace(io) do
        RASN1.parse(os.to_der)
      end
      expect(io.string).to eq(<<~ENDOFDATA
        OCTET STRING id: 4 (0x04), len: 256 (0x820100)
          0000  61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61  aaaaaaaaaaaaaaaa
          0010  61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61  aaaaaaaaaaaaaaaa
          0020  61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61  aaaaaaaaaaaaaaaa
          0030  61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61  aaaaaaaaaaaaaaaa
          0040  61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61  aaaaaaaaaaaaaaaa
          0050  61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61  aaaaaaaaaaaaaaaa
          0060  61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61  aaaaaaaaaaaaaaaa
          0070  61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61  aaaaaaaaaaaaaaaa
          0080  61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61  aaaaaaaaaaaaaaaa
          0090  61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61  aaaaaaaaaaaaaaaa
          00a0  61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61  aaaaaaaaaaaaaaaa
          00b0  61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61  aaaaaaaaaaaaaaaa
          00c0  61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61  aaaaaaaaaaaaaaaa
          00d0  61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61  aaaaaaaaaaaaaaaa
          00e0  61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61  aaaaaaaaaaaaaaaa
          00f0  61 61 61 61 61 61 61 61 61 61 61 61 61 61 61 61  aaaaaaaaaaaaaaaa
      ENDOFDATA
      )
    end

    it 'traces long id' do
      os = Types::OctetString.new(implicit: 128, value: 'a')
      RASN1.trace(io) do
        RASN1.parse(os.to_der)
      end
      expect(io.string).to eq(<<~ENDOFDATA
        BASE id: 128 (0x9f8100), len: 1 (0x01)
          0000  61                                               a
      ENDOFDATA
      )
    end
  end

  module Types
    describe Boolean do
      let(:io) { StringIO.new }

      it 'traces with Boolean format' do
        RASN1.trace(io) do
          RASN1.parse("\x01\x01\xff")
          RASN1.parse("\x01\x01\x01", ber: true)
          RASN1.parse("\x01\x01\x00")
        end
        expect(io.string).to eq(<<~ENDOFDATA
          BOOLEAN id: 1 (0x01), len: 1 (0x01)    TRUE (0xff)
          BOOLEAN id: 1 (0x01), len: 1 (0x01)    TRUE (0x01)
          BOOLEAN id: 1 (0x01), len: 1 (0x01)    FALSE (0x00)
        ENDOFDATA
        )
      end
    end

    [Enumerated, Integer].each do |klass|
      describe klass do
        let(:io) { StringIO.new }
        subject { klass.new(enum: { 'ONE' => 1, 'TWO' => 2 }) }

        it 'traces with enum format (enum key exists)' do
          id = klass::ID
          RASN1.trace(io) do
            subject.parse!("#{id.chr}\x01\x01")
            subject.parse!("#{id.chr}\x01\x02")
          end
          expect(io.string).to eq(<<~ENDOFDATA
            #{klass.type} id: #{id} (0x#{'%02x' % id}), len: 1 (0x01)    ONE (0x01)
            #{klass.type} id: #{id} (0x#{'%02x' % id}), len: 1 (0x01)    TWO (0x02)
          ENDOFDATA
          )
        end

        it 'traces with enum format (enum key does not exist)' do
          id = klass::ID
          RASN1.trace(io) do
            expect { subject.parse!("#{id.chr}\x01\xfe") }.to raise_error(EnumeratedError)
          end
          expect(io.string).to eq(<<~ENDOFDATA
            #{klass.type} id: #{id} (0x#{'%02x' % id}), len: 1 (0x01)    -2 (0xfe)
          ENDOFDATA
          )
        end
      end
    end

    describe GeneralizedTime do
      let(:io) { StringIO.new }

      it 'traces with Time format' do
        gt = GeneralizedTime.new(value: Time.utc(2022, 11, 23, 10, 54, 33))
        RASN1.trace(io) do
          RASN1.parse(gt.to_der)
        end
        expect(io.string).to eq("GeneralizedTime id: 24 (0x18), len: 15 (0x0f)    20221123105433Z\n")
      end

      it 'traces an explicit tag' do
        gt = GeneralizedTime.new(value: Time.utc(2022, 11, 23, 10, 54, 33), explicit: 1, name: 'dueTime')
        RASN1.trace(io) do
          gt.parse!(gt.to_der)
        end
        expect(io.string).to eq(<<~ENDOFDATA
          dueTime EXPLICIT GeneralizedTime id: 1 (0x81), len: 17 (0x11)
            0000  18 0f 32 30 32 32 31 31 32 33 31 30 35 34 33 33  ..20221123105433
            0010  5a                                               Z
            dueTime GeneralizedTime id: 24 (0x18), len: 15 (0x0f)    20221123105433Z
        ENDOFDATA
        )
      end
    end

    describe UtcTime do
      let(:io) { StringIO.new }

      it 'traces with Time format' do
        ut = UtcTime.new(value: Time.utc(2022, 11, 23, 10, 54, 33))
        RASN1.trace(io) do
          RASN1.parse(ut.to_der)
        end
        expect(io.string).to eq("UTCTime id: 23 (0x17), len: 13 (0x0d)    221123105433Z\n")
      end

      it 'traces an explicit tag' do
        ut = UtcTime.new(value: Time.utc(2022, 11, 23, 10, 54, 33), explicit: 2, name: 'dueTime')
        RASN1.trace(io) do
          ut.parse!(ut.to_der)
        end
        expect(io.string).to eq(<<~ENDOFDATA
          dueTime EXPLICIT UTCTime id: 2 (0x82), len: 15 (0x0f)
            0000  17 0d 32 32 31 31 32 33 31 30 35 34 33 33 5a     ..221123105433Z
            dueTime UTCTime id: 23 (0x17), len: 13 (0x0d)    221123105433Z
        ENDOFDATA
        )
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength,Layout/ClosingParenthesisIndentation
