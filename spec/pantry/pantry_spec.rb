require 'spec_helper'
require_relative '../../lib/pantry/base'
require_relative '../../pantries/test_pantry'

module TestPantries
  describe TestPantry do
    let(:subject) {TestPantry.new}
    let(:named) {PantryTest::Named.new(:name => 'Named')}
  
    context 'empty pantry' do
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
  
    context 'with multiple, simple resources' do
      let(:described) {PantryTest::Described.new(:descriptor => 'Described')}

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

    context 'with a single, self-related resource' do
      let(:whole) {PantryTest::Composite.new(:some_identifying_value => 'Some whole')}
      let(:part) {PantryTest::Composite.new(:some_identifying_value => 'Some part')}

      before(:each) do
        whole.parts << part
        part.whole = whole
        subject.can_stack PantryTest::Composite, :id_value_method => :some_identifying_value
      end

      it 'has a stackable with a specified id_value_method_name' do
        whole.id_value_method_names.should == [:some_identifying_value]
      end

      it 'has a stackable that answers its id_value' do
        whole.id_value.should == 'Some whole'
      end
  
      it 'produces stackable data structures for each resource' do
        p = part.to_pantry
        p[:attributes][:some_identifying_value].should == 'Some part'
        p[:foreign_values].should == {:whole => 'Some whole', :owner => nil}
      end
    end

    context 'with two resources, associated polymorphically' do
      let(:whole) {PantryTest::Composite.new(:some_identifying_value => 'Some whole')}
      let(:named) {PantryTest::Named.new(:name => 'Named')}

      before(:each) do
        whole.owner = named
        subject.can_stack PantryTest::Named
        subject.can_stack PantryTest::Composite, :id_value_method => :some_identifying_value
      end
  
      it 'produces stackable data structures for each resource' do
        w = whole.to_pantry
        w[:attributes][:some_identifying_value].should == 'Some whole'
        w[:foreign_values].should == {:owner => 'Named', :whole => nil}
      end
    end

    context 'stacking' do
    
    end

    context 'using' do
    end
  end
end
