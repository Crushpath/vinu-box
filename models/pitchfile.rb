class Pitchfile

	include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :user

  field :file_id, type: Integer
  field :visible, type: Boolean
  field :parent_id, type: Integer
  field :is_Folder, type: Boolean


end