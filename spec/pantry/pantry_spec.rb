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

        it "knows a pantry record's class" do
          p = named.to_pantry
          p.klass.name.should == 'PantryTest::Named'
        end

        it "knows a pantry record's attributes" do
          p = named.to_pantry
          p.attributes[:name].should == 'Named'
        end

        it "knows a pantry record's id_value" do
          p = named.to_pantry
          p.id_values.should == {:name => 'Named'}
        end

        it "an item's pantry is it's enclosing pantry" do
          p = named.to_pantry  
          p.pantry.should == subject
        end
      end

      context 'with multiple, simple resources' do
        let(:described) {PantryTest::Described.new(:descriptor => 'Described')}

        before(:each) do
          subject.can_stack PantryTest::Named, PantryTest::Described
        end

        it 'has a stackable that answers its id_value' do
          described.id_values.should == {:descriptor => 'Described'}
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
          x.id_values.should == {:name => 'Named'}
          y.id_values.should == {:descriptor => 'Described'}
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
          subject.can_stack PantryTest::Composite, :id_value_methods => :some_identifying_value
        end

        it 'has a stackable with a specified id_value_method_name' do
          whole.id_value_method_names.should == [:some_identifying_value]
        end

        it 'has a stackable that answers its id_value' do
          whole.id_values.should == {:some_identifying_value => 'Some whole'}
        end

        it 'produces stackable data structures for each resource' do
          p = part.to_pantry
          p.attributes[:some_identifying_value].should == 'Some part'
          p.foreign_values.should == {:whole  => {:some_identifying_value => "Some whole"}, :owner => nil}
        end

        it 'creates a file with a default name in a default location' do
          whole.save!
          subject.stack
          File.exists?("#{Rails.root}/data/pantries/test_pantry_3.pantry").should == true
        end
      end

      context 'with two resources, associated polymorphically' do
        let(:whole) {PantryTest::Composite.new(:some_identifying_value => 'Some whole')}

        before(:each) do
          whole.owner = named
          subject.can_stack PantryTest::Named
          subject.can_stack PantryTest::Composite, :id_value_methods => :some_identifying_value
        end

        it 'produces stackable data structures for each resource' do
          w = whole.to_pantry
          w.attributes[:some_identifying_value].should == 'Some whole'
          w.foreign_values.should == {:whole => nil, :owner => {:name=>"Named"}}
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
          subject.can_stack PantryTest::Composite, :id_value_methods => :some_identifying_value
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

        before(:each) do
          whole.owner = named
          whole.save!
          named.save!
          subject.can_stack PantryTest::Named
          subject.can_stack PantryTest::Composite, :id_value_methods => :some_identifying_value
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

        before(:each) do
          whole.owner = named
          whole.save!
          named.save!
          subject.can_stack PantryTest::Named
          subject.can_stack PantryTest::Composite, :id_value_methods => :some_identifying_value
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

    context 'on collision' do
      context 'with two resources, associated polymorphically' do
        let(:whole) {PantryTest::Composite.new(:some_identifying_value => 'Some whole')}

        before(:each) do
          whole.owner = named
          whole.save!
          named.save!
          subject.can_stack PantryTest::Named, :on_collision => :replace
          subject.can_stack PantryTest::Composite, :id_value_methods => :some_identifying_value, :on_collision => :replace
        end

        it 'remembers on collision options' do
          subject.options_for(PantryTest::Named).should == {:on_collision => :replace}
          subject.options_for(PantryTest::Composite).should == {:id_value_methods => :some_identifying_value, :on_collision => :replace}
        end

        it 'replaces duplicate when :on_collision option is :replace' do
          whole_updated_at = whole.updated_at
          named_updated_at = named.updated_at
          subject.stack
          subject.use
          w = PantryTest::Composite.find_by_some_identifying_value('Some whole')
          w.updated_at.should_not == whole_updated_at
          w.owner.updated_at.should_not == named_updated_at
        end
      end
    end

    context 'with a scope option given' do
      let(:named2) {PantryTest::Named.new(:name => 'Named 2', :value => 'Bill')}

      before(:each) do
        named.save!
        named2.save!
        subject.can_stack PantryTest::Named, :scope => {:where => {:value => 'Bill'}}
      end

      it 'stacks objects only within scope' do
        subject.stack
        PantryTest::Named.destroy_all
        subject.use
        n = PantryTest::Named.all
        subject.options_for(PantryTest::Named)[:scope].should == {:where => {:value => 'Bill'}}
        n.count.should == 1
        n.first.value.should == 'Bill'
      end
    end

    context 'with a compound id value' do
      context 'with a single, simple resource' do
        let(:described) {PantryTest::Described.new(:descriptor => 'Fresh', :value => 'Coffee')}

        before(:each) do
          subject.can_stack PantryTest::Described, :id_value_methods => [:descriptor, :value]
        end

        it 'has a stackable that answers its id_values' do
          described.id_values.should == {:descriptor => 'Fresh', :value => 'Coffee'}  
        end

        it 'has a stackable that answers its id_value' do
          described.id_value.should == 'Fresh Coffee'
        end

        it "knows a pantry record's id_value" do
          p = described.to_pantry
          p.id_values.should == {:descriptor => 'Fresh', :value => 'Coffee'}  
        end

        it 'stacks & uses correctly' do
          described.save!
          PantryTest::Described.new(:descriptor => 'Fresh', :value => 'Meat').save!
          subject.stack
          PantryTest::Described.destroy_all
          subject.use
          d = PantryTest::Described.all
          d.count.should == 2
          d.first.value.should == 'Coffee'
          d.last.value.should == 'Meat'
        end
      end

      context 'with a uniqueness validator' do
        let(:valued) {PantryTest::Valued.new(:discriminator => 'Toxic', :value => 'Tomatoes')}

        before(:each) do
          subject.can_stack PantryTest::Valued
        end

        it "knows a pantry record's id_values" do
          valued.id_value_method_names.should == [:discriminator, :value]
          p = valued.to_pantry
          p.id_values.should == {:discriminator => 'Toxic', :value => 'Tomatoes'}  
        end
      end
    end
  end
end
