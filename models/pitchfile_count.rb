class PitchfileCount
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :pitchfile

  field :count, type: Integer

end