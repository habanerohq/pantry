require 'spec_helper'
require_relative '../../lib/pantry/base'
require_relative '../../pantries/test_pantry'

module TestPantries
  describe TestPantry do
    let(:subject) {TestPantry.new}
    let(:named) {PantryTest::Named.new(:name => 'Named', :value => 'Fred', :created_at =>  Time.now)}
  
    context 'empty pantry' do
      FileUtils.remove_dir("#{Rails.root}/data/pantries", true)      
      it 'creates a file with a default name in a default location' do
        subject.stack
        File.exists?("#{Rails.root}/data/pantries/test_pantry_1.pantry").should == true
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
          p.klass.name.should == 'PantryTest::Named'
        end

        it "it knows a pantry record's attributes" do
          p = named.to_pantry
          p.attributes[:name].should == 'Named'
        end

        it "it knows a pantry record's id_value" do
          p = named.to_pantry
          p.id_value.should == 'Named'
        end

        it "it knows a pantry record's id_value" do
          p = named.to_pantry
          p.id_value.should == 'Named'
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
          x.attributes[:name].should == 'Named'
          y.attributes[:descriptor].should == 'Described'
          y.class_name.should == 'PantryTest::Described'
          x.id_value.should == 'Named' 
          y.id_value.should == 'Described' 
        end
    
        it 'creates a file with a default name in a default location' do
          named.save!
          described.save!
          subject.stack
          File.exists?("#{Rails.root}/data/pantries/test_pantry_2.pantry").should == true
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
          p.attributes[:some_identifying_value].should == 'Some part'
          p.foreign_values.should == {:whole => 'Some whole', :owner => nil}
        end

        it 'creates a file with a default name in a default location' do
          whole.save!
          subject.stack
          File.exists?("#{Rails.root}/data/pantries/test_pantry_3.pantry").should == true
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
          w.attributes[:some_identifying_value].should == 'Some whole'
          w.foreign_values.should == {:owner => 'Named', :whole => nil}
        end

        it 'creates a file with a default name in a default location' do
          named.save!
          subject.stack
          File.exists?("#{Rails.root}/data/pantries/test_pantry_4.pantry").should == true
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
          ar = p.to_model
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
          pan.attributes[:whole_id] = nil
          ar = pan.to_model
          ar.whole_id.should == p.whole_id
        end
      end

      context 'with two resources, associated polymorphically' do
        let(:whole) {PantryTest::Composite.new(:some_identifying_value => 'Some whole')}
        let(:named) {PantryTest::Named.new(:name => 'Named')}

        before(:each) do
          whole.owner = named
          whole.save!
          subject.can_stack PantryTest::Named
          subject.can_stack PantryTest::Composite, :id_value_method => :some_identifying_value
        end

        it 'can use what it stacks' do
          w = PantryTest::Composite.find_by_some_identifying_value('Some whole')
          o = w.owner
          p = w.to_pantry
          p.attributes[:owner_id] = nil
          ar = p.to_model
          ar.owner_id.should == w.owner_id
        end
      end
    end

    context 'using' do
      context 'with two resources, associated polymorphically' do
        let(:whole) {PantryTest::Composite.new(:some_identifying_value => 'Some whole')}
        let(:named) {PantryTest::Named.new(:name => 'Named')}

        before(:each) do
          whole.owner = named
          whole.save!
          subject.can_stack PantryTest::Named
          subject.can_stack PantryTest::Composite, :id_value_method => :some_identifying_value
        end

        it 'can use a file with a default name in a default location' do
          subject.stack
          PantryTest::Named.destroy_all
          PantryTest::Composite.destroy_all
          subject.use
          w = PantryTest::Composite.find_by_some_identifying_value('Some whole')
          whole.id += 1
          whole.owner_id += 1
          named.id += 1
          whole.should == w
          named.should == w.owner
        end

        it 'skips items whose id_values are already present on the database' do
          subject.stack
          subject.use
          w = PantryTest::Composite.find_all_by_some_identifying_value('Some whole').last
          whole.should == w
          named.should == w.owner
        end
      end
    end
  end
end
