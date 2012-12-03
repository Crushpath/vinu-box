class User
	
  include Mongoid::Document
  include Mongoid::Timestamps

  has_many :pitchfiles

	field :box_user_id, type: Integer

  validates_presence_of :box_user_id

end