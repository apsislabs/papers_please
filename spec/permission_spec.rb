require 'spec_helper'

RSpec.describe PapersPlease::Permission do
  subject { PapersPlease::Permission }
  let(:book) { double('Book') }

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
  end
end
