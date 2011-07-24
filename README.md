Original blog post (January 3, 2011)
http://vitobotta.com/serialisable-validatable-tableless-model/


# Tableless Model

This is an extended Hash that has a defined collection of method-like attributes, and only these attributes can be set or read from the hash. 
Optionally, you can also set default values and enforce data types for these attributes.

Tableless Model behaves in a similar way to normal ActiveRecord models in that it also supports validations and can be useful, for example, to reduce database complexity in some cases, by removing associations and therefore tables. 

In particular, by using Tableless Model, you could save tables whenever you have one to one associations between a parent model and a child model containing options, settings, debugging information or any other collection of attributes that belongs uniquely to a single parent object.

Removing database tables also means reducing the number of queries to fetch associations, therefore it can also help a little bit with performance.


## Installation

Tableless Model is available as a Rubygem:

``` bash
gem install tableless_model
``` 		

== Usage

For example's sake, say we have these two models:

1)

``` ruby
class Page < ActiveRecord::Base

	# having columns such as id, title, etc

	has_one :seo_options

end
```

2) 

``` ruby
class SeoOptions < ActiveRecord::Base

	set_table_name "seo_options"

	# having columns such as id, title_tag, meta_description, meta_keywords, 
	# noindex, nofollow, noarchive, page_id

	belongs_to :page

end
```

So that each instance of Page has its own SEO options, and these options/settings only belong to a page, so we have a one to one association, and our database will have the tables "pages", and "seo_options".

Using Tableless Model, we could remove the association and the table seo_options altogether, by storing those options in a column of the pages table, in a YAML-serialized form. So the models become:


1)

``` ruby
class Page < ActiveRecord::Base

	# having columns such as id, title, seo, etc

	has_tableless :seo => SeoOptions

end
```

2) 

``` ruby
class SeoOptions < ActiveRecord::TablelessModel

  attribute :title_tag,         :type => :string,  :default => "default title tag"
  attribute :meta_description,  :type => :string,  :default => ""  
  attribute :meta_keywords,     :type => :string,  :default => ""  
  attribute :noindex,           :type => :boolean, :default => false 
  attribute :nofollow,          :type => :boolean, :default => false 
  attribute :noarchive,         :type => :boolean, :default => false 

end
``` 

That's it. 

When you now create an instance of SeoOptions, you can get and set its attributes as you would do with a normal model:

``` ruby
seo_options = SeoOptions.new
 	=> <#SeoOptions meta_description="" meta_keywords="" noarchive=false nofollow=false noindex=false title_tag="default title tag">

seo_options.title_tag
	=> "default title tag"

seo_options.title_tag = "new title tag"
	=> "new title tag"
``` 
			
Note that inspect	shows the properties of the Tableless Model in the same way it does for ActiveRecord models.
Of course, you can also override the default values for the attributes when creating a new instance:

``` ruby
seo_options = SeoOptions.new( :title_tag => "a different title tag" )
 	=> <#SeoOptions meta_description="" meta_keywords="" noarchive=false nofollow=false noindex=false title_tag="a different title tag">
``` 

Now, if you have used the has_tabless macro in the parent class, Page, each instance of Page will store directly its YAML-serialized SEO settings in the column named "seo". 

``` ruby
page = Page.new

page.seo
 	=> <#SeoOptions meta_description="" meta_keywords="" noarchive=false nofollow=false noindex=false title_tag="default title tag">

page.seo.title_tag = "changed title tag"
 	=> <#SeoOptions meta_description="" meta_keywords="" noarchive=false nofollow=false noindex=false title_tag="changed title tag">
``` 

And this is how the content of the serialized column would look like in the database if you saved the changes as in the example

``` yaml
--- !map:SeoOptions 
noarchive: false
meta_description: 
meta_keywords: 
nofollow: false
title_tag: "changed title tag"
noindex: false
``` 

You can also pass a lambda/Proc when defining the default value of an attribute, so that the actual value will be calculated at runtime when a new instance of the tableless mode is being initialised:

``` ruby
class SeoOptions < ActiveRecord::TablelessModel

  attribute :created_at, :type => :time, :default => lambda { Time.now }   

end

```

Then, when the tableless model is initialised together with the parent model, the default value will be calculated and assigned in that moment:

``` ruby
>> SeoOptions.new
=> <#SeoOptions created_at_=Sun Jul 24 19:26:33 +0100 2011>
>> SeoOptions.new
=> <#SeoOptions created_at_=Sun Jul 24 19:26:37 +0100 2011>
>> SeoOptions.new
=> <#SeoOptions created_at_=Sun Jul 24 19:26:43 +0100 2011>
```

Of course, if a value is specified for an attribute when creating an instance of the tableless mode, the default value specified for that attribute will be ignored, including lambdas/procs:

``` ruby
>> SeoOptions.new :created_at => Time.local(2011, 7, 24, 18, 47, 0)
=> <#SeoOptions created_at=Sun Jul 24 18:47:00 +0100 2011>
```

For each of the attribute defined in the tableless model, shortcuts for both setter and getter are automatically defined in the parent model, unless the parent model already has a method of its own by the same name.

So, for instance, if you have the tableless model:

``` ruby
class SeoOptions < ActiveRecord::TablelessModel

  attribute :title_tag,         :type => :string,  :default => "default title tag"

end
```

which is used by a parent model:

``` ruby
class Page < ActiveRecord::Base

	has_tableless :seo => SeoOptions

end
```

you can get/set attributes of the tableless model directly from the parent model:


``` ruby
# this...
>> page.title_tag
=> "default title tag"

# is same as...
>> page.seo_options.title_tag
=> "default title tag"
```

For boolean attributes (or also truthy/falsy ones) you can also make calls to special getters ending with "?", so to get true or false in return, depending on the actual value of the attribute:

``` ruby
# this...
>> page.title_tag?
=> true
```


## Validations

Tableless Model uses the Validatable gem to support validations methods and callbacks (such as "after_validation").
Note: it currently uses the Rails 2.x syntax only.

Example:

``` ruby
class SeoOptions < ActiveRecord::TablelessModel

  attribute :title_tag,         :type => :string,  :default => ""
  attribute :meta_description,  :type => :string,  :default => ""  
  attribute :meta_keywords,     :type => :string,  :default => ""  
  attribute :noindex,           :type => :boolean, :default => false 
  attribute :nofollow,          :type => :boolean, :default => false 
  attribute :noarchive,         :type => :boolean, :default => false 

  validates_presence_of :meta_keywords
	
end
``` 

Testing:

``` ruby
x = SeoOptionsSettings.new
 => <#SeoOptions meta_description="" meta_keywords="" noarchive=false nofollow=false noindex=false title_tag="">

x.valid?
 => false

x.meta_keywords = "test"
 => "test"

x.valid?
 => true 
``` 

## TODO

* Update validations syntax to that of Rails 3
* Support for associations


## Authors

* Vito Botta ( http://vitobotta.com )

## Contributing

* Fork the project on Github.
* Make your feature addition or bug fix.
* Add specs for it, making sure all specs green.
* Commit, and send me a pull request.

## Compatibility

* Tested with REE/1.8.7, 1.9.2

## Change log

24.07.2011 - Added support for passing Proc/lamba when defining the default attribute of a value

## License

MIT License. Copyright 2010 Vito Botta. http://vitobotta.com

