require 'spec_helper'

RSpec.describe PapersPlease::Permission do
  subject { PapersPlease::Permission }
  let(:book) { double('Book') }

  it 'requires a key and subject' do
    expect { subject.new }.to raise_error(ArgumentError)
    expect { subject.new(:key) }.to raise_error(ArgumentError)
    expect { subject.new(:key, book) }.not_to raise_error
  end

  it 'allows query and predicate' do
    stub_proc = proc { true }
    perm = subject.new(:key, book, predicate: stub_proc, query: stub_proc)

    expect(perm.predicate).to be stub_proc
    expect(perm.query).to be stub_proc
  end

  describe '#matches?' do
    let(:permission) { subject.new(:read, book) }

    it 'matches' do
      expect(permission.matches?(:read, book)).to be true
    end

    it 'does not match' do
      expect(permission.matches?(:write, book)).to be false
    end
  end

  describe '#granted?' do
    let(:true_permission) { subject.new(:read, book, predicate: proc { true }) }
    let(:false_permission) { subject.new(:read, book, predicate: proc { false }) }
    let(:stub_proc) { proc { true } }
    let(:stub_perm) { subject.new(:read, book, predicate: stub_proc) }

    it 'is true for true permission' do
      expect(true_permission.granted?).to be true
    end

    it 'is false for false permission' do
      expect(false_permission.granted?).to be false
    end

    it 'calls the predicate proc' do
      expect(stub_proc).to receive(:call).and_return(true)
      expect(stub_perm.granted?).to be true
    end

    it 'calls the predicate proc' do
      expect(stub_proc).to receive(:call).with(:arg).and_return(true)
      expect(stub_perm.granted?(:arg)).to be true
    end

    it 'returns false if query is not a proc' do
      perm = subject.new(:read, book, predicate: 'bad predicate')
      expect(perm.granted?).to be false
    end
  end

  describe 'fetch' do
    let(:array_permission) { subject.new(:read, book, query: proc { [] }) }
    let(:empty_permission) { subject.new(:read, book, query: proc { nil }) }
    let(:stub_proc) { proc { [] } }
    let(:stub_perm) { subject.new(:read, book, query: stub_proc) }

    it 'is array for array permission' do
      expect(array_permission.fetch).to eq []
    end

    it 'is nil for nil permission' do
      expect(empty_permission.fetch).to eq nil
    end

    it 'calls the predicate proc' do
      expect(stub_proc).to receive(:call).and_return([])
      expect(stub_perm.fetch).to eq []
    end

    it 'calls the predicate proc' do
      expect(stub_proc).to receive(:call).with(:arg).and_return(nil)
      expect(stub_perm.fetch(:arg)).to eq nil
    end

    it 'returns nil if query is not a proc' do
      perm = subject.new(:read, book, query: 'bad query')
      expect(perm.fetch).to be nil
    end
  end
end
