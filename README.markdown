Pantry is essentially a database unload/reload tool with smarts. It's designed to deal with advanced replication, migration and merging problems. While it depends on ActiveRecord, it's database-agnostic.

# Motivation

Suppose you have a category table on each of two databases. In the first database, the category table contains the following rows:

<table>
  <tr>
    <th>id</th>
    <th>descriptor</th>
    <th>abbreviation</th>
  </tr>
  <tr>
    <td>1</td>
    <td>Black</td>
    <td>B</td>
  </tr>
  <tr>
    <td>2</td>
    <td>White</td>
    <td>W</td>
  </tr>
  <tr>
    <td>3</td>
    <td>Cyan</td>
    <td>C</td>
  </tr>
  <tr>
    <td>4</td>
    <td>Magenta</td>
    <td>M</td>
  </tr>
  <tr>
    <td>4</td>
    <td>Yellow</td>
    <td>Y</td>
  </tr>
</table>

while the category table in the second database contains:

<table>
  <tr>
    <th>id</th>
    <th>descriptor</th>
    <th>abbreviation</th>
  </tr>
  <tr>
    <td>3</td>
    <td>Red</td>
    <td>R</td>
  </tr>
  <tr>
    <td>4</td>
    <td>Green</td>
    <td>G</td>
  </tr>
  <tr>
    <td>4</td>
    <td>Blue</td>
    <td>B</td>
  </tr>
  <tr>
    <td>5</td>
    <td>Black</td>
    <td>0</td>
  </tr>
  <tr>
    <td>6</td>
    <td>White</td>
    <td>1</td>
  </tr>
</table>

Now suppose you want to merge the contents of both table instances into the first database. It's not as simple as simply appending the contents of the second table into the first because:
* there are duplicated rows,
* the ids of the duplicated rows do not match, and
* the values of the abbreviation column in the duplicated rows do not match.

Pantry helps you merge the data and allows you to declare how you want the conflicts resolved. Of course, in Rails tradition, Pantry already has some opinions on how you might want to do this and implements some sensible defaults.

# Stacking a pantry

To start unloading a database you create a subclass of Pantry::Base and declare which tables you wish to "stack". For example:

    class FirstPantry < Pantry::Base
      can_stack Category
    end

declares that FirstPantry stacks only rows from the table associated with the Category class. To perform the stacking, write in your code somewhere:

    a_pantry = FirstPantry.new
    a_pantry.stack

NOTE: by default we put pantry classes in the pantries folder of the rails project, e.g my_rails_project/pantries/first_pantry.rb
    
# Value keys

The first challenge for pantry


# Selective stacks and uses
Pantry unloads selected rows of selected tables of a database. It can then selectively load those rows into another database that may already have other data.

    This causes some challenges especially around primary keys. Because data may already exist in a table that is going to have data loaded into it, the primary keys of the incoming rows make already exist on the database. New primary keys need to be allocated to the incoming data.

    This has a knock-on effect for foreign keys, because rows from other incoming tables may have foreign keys that are now invalid because primary keys have been changed. Pantry therefore provides a scheme for relocating rows and correcting foreign keys.

    The most straightforward way to do this is to define an alternative scheme for locating rows in tables based on the value data in the row. If a row can be located using this alternative scheme, it's id can be retrieved and substituted in for any invalidated foreign key that needs it. Pantry handles polymorphic foreign keys where both a class type and value id is required to locate the target object.

    In the simplest case, a row may be uniquely identified by a single column. Pantry simply needs to know what that column should be. Pantry looks for uniqueness constraints in the ActiveRecord to decide that column. Failing that, Pantry has a default precedence of column names to look for on a row(a user can override this precedence). Pantry looks for columns on the row in the order of this precedence and the first one that is found is used as the value key for the record. The value key is stored with all foreign keys during the unload process so that foreign key correction can work during loading.

    A suggested default value key precedence might be:

    [:descriptor, :name, :label, :title]

    A user can define a value key on a table-by-table basis. Such customised keys can be compound, ie where a row cannot be identified by the value of a single column, a user can define multiple columns so that uniqueness is assured. It could be that one of the columns so required is itself a foreign key. Pantry handles this by recursively embedding the values of the foreign key target that are required to identify that record.

    Pantry implements schemes for handling object clashes, ie when an incoming load record has the same value id as an existing record. According to these schemes, either the existing record or the new record is the one that persists after upload. In order of precedence:

    - take the record with the later created_at value (but allow a user to specify earlier created if desired)
    - take the record with the later updated_at value (but allow a user to specify earlier updated if desired)
    - persist the incoming row
    - leave the existing row untouched

    A user may override this precedence by nominating any of these schemes on a table-by-table basis. Additionally, a user can nominate a callback method that returns an ActiveRecord for pantry to persist. Inside the callback, a user can implement whatever decision process they desire and may even synthesize a new object, taking values for both existing and incoming rows.

    During the load, it is possible that the value id for a foreign key does not identify an existing record. This can be due to the complexity of the incoming data, such as when following trail of foreign keys exposes circular associations. Pantry handles this by parsing the incoming data multiple times deferring the processing of "difficult" records for subsequent parses.

    Pantry allows you to define nests of objects to unload and reload. This makes the process simpler and faster because foreign keys in lower-nested objects that point to higher-nested objects can be resolved more easily.
