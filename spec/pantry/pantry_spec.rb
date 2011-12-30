require 'spec_helper'
require_relative '../../lib/pantry/base'
require_relative '../../pantries/test_pantry'

module TestPantries
  describe TestPantry do
    let(:subject) {TestPantry.new}
    let(:described) {PantryTest::Described.new(:descriptor => 'Described')}
    let(:named) {PantryTest::Named.new(:name => 'Named')}
  
    context 'empty pantry' do
      let(:subject) {TestPantry.new}
    
      it 'stacks nothing gracefully' do
        subject.stack
      end

      it 'uses nothing gracefully' do
        subject.use
      end
    end
  
    context 'with a single, simple resource' do
      before(:each) do
        subject.can_stack PantryTest::Named
      end
    
      it 'remembers what to stack' do
        subject.stackables.should == [PantryTest::Named]
      end
    
      it 'has a stackable with a default id_value_method_name' do
        named.id_value_method_names.should == [:name]
      end

      it 'has a stackable that answers its id_values' do
        named.id_values.should == {:name => 'Named'}  
      end
  
      it 'has a stackable that answers its id_value' do
        named.id_value.should == 'Named'  
      end
    
      it 'produces a stackable data structure' do
        p = named.to_pantry
        p[:attributes][:name].should == 'Named'
        p[:value_ids].should == nil
      end
    end
  
    context 'with a multiple, simple resource' do
      before(:each) do
        subject.can_stack PantryTest::Named, PantryTest::Described
      end

    it 'has a stackable that answers its id_value' do
      described.id_value.should == 'Described'  
    end
    
      it 'has a stackable with a default id_value_method_name' do
        described.id_value_method_names.should == [:descriptor]
      end
    
      it 'remembers what to stack' do
        subject.stackables.should == [PantryTest::Named, PantryTest::Described]
      end
    
      it 'produces stackable data structures for each resource' do
        x = named.to_pantry
        y = described.to_pantry
        x[:attributes][:name].should == 'Named'
        y[:attributes][:descriptor].should == 'Described'
        x.has_key?(:foreign_values)
        y.has_key?(:foreign_values)
      end
    end

    context 'stacking' do
    
    end

    context 'using' do
    end
  end
end
