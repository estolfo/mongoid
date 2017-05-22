require 'spec_helper'

describe 'Binding with foreign keys' do

  context 'when the relation is belongs_to and has_many' do

    before do
      class Flower
        include Mongoid::Document

        has_many :petals
        field :type
      end


      class Petal
        include Mongoid::Document
        belongs_to :flower, optional: true
      end
    end

    after do
      Object.send(:remove_const, :Flower)
      Object.send(:remove_const, :Petal)
    end

    context 'when the parent is persisted' do

      context 'when the child is persisted' do

        let(:flower) do
          Flower.create
        end

        let(:petal) do
          Petal.create
        end

        before do
          petal.flower = flower
        end

        it 'assigns the parent id to the child' do
          expect(petal.flower_id).not_to be_nil
        end
      end

      context 'when the child is not persisted' do

        let(:flower) do
          Flower.create
        end

        let(:petal) do
          Petal.new
        end

        before do
          petal.flower = flower
        end

        it 'assigns the parent id to the child' do
          expect(petal.flower_id).not_to be_nil
        end
      end
    end

    context 'when the parent is not persisted' do

      context 'when the child is persisted' do

        let(:flower) do
          Flower.new
        end

        let(:petal) do
          Petal.create
        end

        before do
          petal.flower = flower
        end

        it 'does not assign the parent id to the child' do
          expect(petal.flower_id).to be_nil
        end

        context 'when the parent is subsequently saved' do

          before do
            flower.save
          end

          it 'allows access to the list of children' do
            expect(flower.petals).to eq([ petal ])
          end
        end
      end

      context 'when the child is not persisted' do

        let(:flower) do
          Flower.new
        end

        let(:petal) do
          Petal.new
        end

        before do
          petal.flower = flower
        end

        it 'does not assign the parent id to the child' do
          expect(petal.flower_id).to be_nil
        end

        context 'when the child is subsequently saved' do

          before do
            petal.save
          end

          it 'does not return the list of children' do
            expect(flower.petals(reload: true)).to be_empty
          end
        end

        context 'when the parent is subsequently saved' do

          before do
            flower.save
          end

          it 'does not assign the parent id on the child' do
            expect(petal.flower_id).to be_nil
          end

          it 'does not return the list of children' do
            expect(flower.petals(reload: true)).to be_empty
          end
        end
      end
    end
  end

  context 'when the relation is belongs_to and has_one' do

    before do
      class Flower
        include Mongoid::Document

        has_one :petal
        field :type
      end


      class Petal
        include Mongoid::Document
        belongs_to :flower, optional: true
      end
    end

    after do
      Object.send(:remove_const, :Flower)
      Object.send(:remove_const, :Petal)
    end

    context 'when the parent is persisted' do

      context 'when the child is persisted' do

        let(:flower) do
          Flower.create
        end

        let(:petal) do
          Petal.create
        end

        before do
          petal.flower = flower
        end

        it 'assigns the parent id to the child' do
          expect(petal.flower_id).not_to be_nil
        end
      end

      context 'when the child is not persisted' do

        let(:flower) do
          Flower.create
        end

        let(:petal) do
          Petal.new
        end

        before do
          petal.flower = flower
        end

        it 'assigns the parent id to the child' do
          expect(petal.flower_id).not_to be_nil
        end
      end
    end

    context 'when the parent is not persisted' do

      context 'when the child is persisted' do

        let(:flower) do
          Flower.new
        end

        let(:petal) do
          Petal.create
        end

        before do
          petal.flower = flower
        end

        it 'does not assign the parent id to the child' do
          expect(petal.flower_id).to be_nil
        end

        context 'when the parent is subsequently saved' do

          before do
            flower.save
          end

          it 'allows access to the list of children' do
            expect(flower.petal).to eq(petal)
          end
        end
      end

      context 'when the child is not persisted' do

        let(:flower) do
          Flower.new
        end

        let(:petal) do
          Petal.new
        end

        before do
          petal.flower = flower
        end

        it 'does not assign the parent id to the child' do
          expect(petal.flower_id).to be_nil
        end

        context 'when the child is subsequently saved' do

          before do
            petal.save
          end

          it 'returns the child' do
            expect(flower.petal).to eq(petal)
          end
        end

        context 'when the parent is subsequently saved' do

          before do
            flower.save
          end

          it 'assigns the parent id to the child' do
            expect(petal.flower_id).not_to be_nil
          end

          it 'returns the child' do
            expect(flower.petal).to eq(petal)
          end
        end
      end
    end
  end
end