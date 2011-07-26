$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require "active_record"
require "timecop"
require "tableless_model"

ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => ":memory:")
ActiveRecord::Base.connection.execute(" create table test_models (id integer, options varchar(50)) ")
ActiveRecord::Base.connection.execute(" create table some_models (id integer, settings varchar(50)) ")


