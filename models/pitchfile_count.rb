class PitchfileCount
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :pitchfile

  field :count, type: Integer

  class << self
    def sorted
      order_by([[:count,:desc]]).where(:count.gt => 0).entries 
    end

  end

end
