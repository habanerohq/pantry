Pantry is essentially a database unload/reload tool with smarts. It's designed to deal with advanced replication, migration and merging problems. While it depends on <code>ActiveRecord</code>, it's database-agnostic.

# Motivation

Suppose you have a category table on each of two databases. In the first database, the category table contains the following rows:

<table>
  <tr>
    <th>id</th>
    <th>descriptor</th>
    <th>abbreviation</th>
    <th>superscheme_id</th>
  </tr>
  <tr>
    <td>1</td>
    <td>CMYK Colours</td>
    <td>CMYK</td>
    <td></td>
  </tr>
  <tr>
    <td>2</td>
    <td>Black</td>
    <td>B</td>
    <td>1</td>
  </tr>
  <tr>
    <td>3</td>
    <td>White</td>
    <td>W</td>
    <td>1</td>
  </tr>
  <tr>
    <td>4</td>
    <td>Cyan</td>
    <td>C</td>
    <td>1</td>
  </tr>
  <tr>
    <td>5</td>
    <td>Magenta</td>
    <td>M</td>
    <td>1</td>
  </tr>
  <tr>
    <td>6</td>
    <td>Yellow</td>
    <td>Y</td>
    <td>1</td>
  </tr>
</table>

while the category table in the second database contains:

<table>
  <tr>
    <th>id</th>
    <th>descriptor</th>
    <th>abbreviation</th>
    <th>superscheme_id</th>
  </tr>
  <tr>
    <td>1</td>
    <td>RGB Colours</td>
    <td>RGB</td>
    <td></td>
  </tr>
  <tr>
    <td>3</td>
    <td>Red</td>
    <td>R</td>
    <td>1</td>
  </tr>
  <tr>
    <td>4</td>
    <td>Green</td>
    <td>G</td>
    <td>1</td>
  </tr>
  <tr>
    <td>5</td>
    <td>Blue</td>
    <td>B</td>
    <td>1</td>
  </tr>
  <tr>
    <td>6</td>
    <td>Black</td>
    <td>0</td>
    <td>1</td>
  </tr>
  <tr>
    <td>7</td>
    <td>White</td>
    <td>1</td>
    <td>1</td>
  </tr>
</table>

Now suppose you want to merge the contents of both table instances into the first database. It's not as simple as simply appending the contents of the second table into the first because:

* there are duplicated rows,
* the ids of the duplicated rows do not match, and
* the values of the abbreviation column in the duplicated rows do not match.

Pantry helps you merge the data and allows you to declare how you want the conflicts resolved. Of course, in Rails tradition, Pantry already has some opinions on how you might want to do this and implements some sensible defaults.

# Stacking a pantry

To start unloading the current environment's database you create a subclass of <code>Pantry::Base</code> and declare which tables you wish to "stack". For example:

    class FirstPantry < Pantry::Base
      def initialize      
        can_stack Category
      end
    end

declares that <code>FirstPantry</code> stacks only rows from the table associated with the <code>Category</code> class. To perform the stacking, write in your code somewhere:

    a_pantry = FirstPantry.new
    a_pantry.stack
    
Mutliple stacks can be declared in one statement:

    can_stack Category, SomeOtherClass, ...

NOTE: by default we put pantry classes in the pantries folder of the rails project, e.g my_rails_project/pantries/first_pantry.rb

## Where pantry stacks its data

The <code>stack</code> method creates a pantry file in the data/pantries of your project (It will create the directory if it does not exist). The file name defaults to the underscored pantry subscripted with an auto-generated gernation number. Therefore, the first time you stack an instance of <code>FirstPantry</code>, it will create a file called data/pantries/first_pantry_1.pantry

We are yet to provide an overriding capability for this.
    
## Value ids

The first challenge for pantry is how to deal with inconsistent and conflicting ids. To do this pantry looks for a "value id" amongst the columns of the table. A value id is a column, or collection of columns, that uniquely identifies each row in the table. Pantry assumes such a combination of columns exists that will produce a unique value key. Otherwise, why is the row stored in the database? Pantry can use foreign keys in a value key and will will recursively discover the value id of the object being referenced by a foreign key.

Pantry determines the value id according to the following strategy:

1. first, it check to see if you have declared a value key explicitly
3. next, it looks for <code>validates_uniqueness_of</code> validators in the corresponding model, and takes the first one to be the value id
2. next, it looks for columns that are named as if they could contain unique data and selects the first one it finds as the value id. The columns it looks for (in order) are: <code>descriptor</code>, <code>name</code>, <code>label</code>, <code>title</code>
4. finally, if Pantry cannot determine a value id it will not stack rows from the table.

In the example above, assuming there are no validators declared (yes, we know there should be!), Pantry will use descriptor as the value id. That means that when these tables are merged together, duplicates arise for each of the descriptors 'black' and 'white'. When it comes time to use the stacked <code>FirstPantry</code> in the second database, Pantry will employ a merge strategy to ensure duplicates do not persist. If you want all rows to persist on the second database, you will need to explicitly define a value id for the table.

### Explicitly defining a value id

Examples:

    can_stack Category, :id_value_methods => :abbreviation
    can_stack Category, :id_value_methods => [:descriptor, :abbreviation]

To include a foreign key in the value id, specify the method name of the corresponding association. For example, assuming the <code>Category</code> includes the snippet:

    :belongs_to superscheme, :class_name => 'Category'

you can define a pantry with:

    can_stack Category, :id_value_methods => [:descriptor, :superscheme]

## Selective stacks

Pantry allows you to scope which rows of a table it stacks and uses. For example, you could write:

    can_stack Category, :scope => {:where => {:superscheme_id => 1}}

Pantry translates each key in the <code>scope</code> option into a method name that it sends to the active record, with each corresponding key being the input arguments to the method. The above example would be translated as:

    Category.where(:superscheme_id => 1)

# Using a stacked pantry

To load data from a previously stacked pantry into the current environment's database, write in your code somewhere:

    a_pantry = FirstPantry.new
    a_pantry.use
    
Pantry will look for the latest generated file in data/pantries for <code>FirstPantry</code> and use that file, e.g first_pantry_6.pantry.

Pantry works by checking whether a row exists that matches its stacked value id. If there is no match, Pantry can insert a new row, otherwise it will employ an on_collision strategy to decide what to do (see below).

## Resolving foreign keys

Any foreign keys on the stacked rows cannot be relied upon in the target database. This is because newly loaded rows will have different keys to the those they had in their original database. Any foreign keys that refer to them become invalid. So as Pantry stacks a row, it examines the corresponding model's associations and determines a value id for each foreign key on the row. Pantry stores all foreign value ids when it stacks a row so that during a load, it can calculate a new foreign key on the target database.

Pantry can handle polymorphic associations.

## Stack references

Now that we've discussed how pantry resolves foreign keys, let's look a more advanced stacking scenario.

Sometimes you may want to stack records that contain foreign keys to records that you <italics>don't</italics> want to stack. You'll want to do this if you have a target database that already has those other records loaded. 

Let's look at an example. Suppose you have a target database of customers, purchase orders and order items. Suppose you have another source database (let's call it the source database) that has the customers replicated, but the purchase orders are unique, maybe because they're from a different sales territory. You want to stack only the purchase order and order item records from the source database, not the customer records, because they are duplicated in the target database.

In this scenario we still need to know how to find the customer records on the target database so that we add the purchase orders to the correct customers. This is just another case of defining what the id_values are for customers. We use the <code>refers_to</code> to do this.

    class OrderPantry < Pantry::Base
      def initialize      
        refers_to Customer, id_value_methods => [:customer_number]
        can_stack PurchaseOrder, id_value_methods => [:purchase_order_number]
        can_stack OrderItem, id_value_methods => [:order, :description]
      end
    end

When this pantry is stacked, any time the process encounters a foreign_key that points to a customer, it will generate the correct id_values and store them in the pantry. When the pantry is used later, the process uses the stacked id_values for customers to locate the correct customer on the target database and uses its id as the foreign key wherever it's needed.

Using this technique, you can "stitch" data records from many different databases, as long as you can devise a scheme for defining id_values for all the records you want to stack and use.

## Handling collisions

Pantry implements strategies for handling row collisions, i.e when a stacked row has the same value id as an existing row on the target database. According to these strategies, usually either the existing row or the new row is the one that persists after upload. In order of precedence:

1. first, if a <code>created_at</code> column exists, Pantry takes the row with the later <code>created_at</code> value (this is not yet implemented)
2. next, if an <code>updated_at</code> column exists, Pantry takes the row with the later <code>updated_at</code> value (this is not yet implemented)
3. finally, Pantry will skip the incoming stacked row leave the existing row untouched

## Explicitly defining an on-collision strategy

You can override the on-collision strategy in a number of ways. Here are some examples:

    first_pantry.can_stack Category, :on_collision => :replace
  
* Pantry will update an existing row with the values of the incoming stacked row

    first_pantry.can_stack Category, :on_collision => :earlier_creation
  
* Pantry will take the row with the earlier <code>created_at</code> (not yet implemented)

    first_pantry.can_stack Category, :on_collision => :earlier_update
  
* Pantry will take the row with the earlier <code>updated_at</code> (not yet implemented)

In very rare circumstances, you may need to implement your own on-collision strategy. You can do this accordingly (not yet implemented):

    class FirstPantry < Pantry::Base
      can_stack Category, :on_collision => :resolve_collision #this can be any method name as long as you implement it in your pantry.
  
      def resolve_collision(existing, incoming)
        # write your implementation
      end
    end

The callback takes two arguments, each is an instance of the <code>ActiveRecord</code> model class that the pantry can stack. The first represents the state of the existing object on the target database while the second is a temporarily created object representing the state of the incoming row. If you use a callback you probably want to conditionally take some attribute values from the incoming object then update the existing object and save it. 

## Multiple passes of the incoming stacks (not yet implemented)

During the load, it is possible that the value id for a foreign key does not identify an existing row. This can be due to the complexity of the incoming data, such as when following trail of foreign keys exposes circular associations. Pantry handles this by parsing the incoming data multiple times deferring the processing of "difficult" rows for subsequent parses.

## Stack nesting (not yet implemented)

Pantry allows you to define nests of objects to unload and reload. This makes the process simpler and faster because foreign keys in lower-nested objects that point to higher-nested objects can be resolved more easily.

  class InventoryPantry < Pantry::Base
    can_stack Invoice do
      can_stack Item
    end
  end
