class Lesson < ApplicationRecord
  belongs_to :course_module, counter_cache: true
  has_many :local_contents, dependent: :destroy

  accepts_nested_attributes_for :local_contents, allow_destroy: true
end
