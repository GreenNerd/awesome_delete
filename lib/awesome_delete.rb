require 'active_record'
require 'awesome_delete/delete_extension'

ActiveRecord::Base.send :extend, AwesomeDelete::DeleteExtension