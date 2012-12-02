class User
	
  include Mongoid::Document
  include Mongoid::Timestamps

  has_many :pitchfiles

	field :box_user_id, type: Integer

end