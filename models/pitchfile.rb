class Pitchfile

	include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :user
  has_one :pitchfile_count

  field :file_id, type: Integer
  field :name, type: String
  field :visible, type: Boolean, default: false
  field :parent_id, type: Integer
  field :is_Folder, type: Boolean

  validates_presence_of :file_id, :parent_id

  def count
    pitchfile_count.count
  end
end
