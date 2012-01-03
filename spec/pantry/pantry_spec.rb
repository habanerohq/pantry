require 'spec_helper'
require_relative '../../lib/pantry/base'
require_relative '../../pantries/test_pantry'

module TestPantries
  describe TestPantry do
    let(:subject) {TestPantry.new}
    let(:named) {PantryTest::Named.new(:name => 'Named', :value => 'Fred', :created_at =>  Time.now)}
  
    context 'empty pantry' do
      it 'stacks nothing gracefully' do
        subject.stack
      end

      it 'uses nothing gracefully' do
        subject.use
      end
    end
    
    context 'stacking' do    
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

        it "it knows a pantry record's class" do
          p = named.to_pantry
          subject.klass(p).name.should == 'PantryTest::Named'
        end

        it "it knows a pantry record's attributes" do
          p = named.to_pantry
          subject.attributes(p)[:name].should == 'Named'
        end

        it "it knows a pantry record's id_value" do
          p = named.to_pantry
          subject.id_value(p).should == 'Named'
        end

        it "it knows a pantry record's foreign_values" do
          p = named.to_pantry
          p.should have_key(:foreign_values)
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
          y[:class_name].should == 'PantryTest::Described'
          x[:id_value].should == 'Named' 
          x.should have_key(:foreign_values)
          y[:id_value].should == 'Described' 
          y.should have_key(:foreign_values)
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
          subject.attributes(p)[:some_identifying_value].should == 'Some part'
          subject.foreign_values(p).should == {:whole => 'Some whole', :owner => nil}
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
    end

    context 'using' do
      context 'with a single, simple resource' do
        before(:each) do
          subject.can_stack PantryTest::Named
        end

        it 'can use what it stacks' do
          p = named.to_pantry
          ar = subject.to_active_record(p)
          ar.attributes.should == named.attributes
        end
      end

      context 'with a single, self-related resource' do
        let(:whole) {PantryTest::Composite.new(:some_identifying_value => 'Some whole')}
        let(:part) {PantryTest::Composite.new(:some_identifying_value => 'Some part')}

        before(:each) do
          whole.parts << part
          whole.save!
          subject.can_stack PantryTest::Composite, :id_value_method => :some_identifying_value
        end

        it 'can use what it stacks' do
          w = PantryTest::Composite.find_by_some_identifying_value('Some whole')
          p = w.parts.first
          pan = p.to_pantry
          pan[:attributes][:whole_id] = nil
          ar = subject.to_active_record(pan)
          ar.whole_id.should == p.whole_id
        end
      end
    end
  end
end
