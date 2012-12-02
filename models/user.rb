class User
	include Mongoid::Document
	field :user_id, type: Integer
	field :folder_id, type: Integer
end