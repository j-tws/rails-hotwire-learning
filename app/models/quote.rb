class Quote < ApplicationRecord
  validates :name, presence: true

  scope :ordered, -> { order(id: :desc) }

  # this line is the syntactic sugar for the below
  broadcasts_to ->(quote) { "quotes" }, inserts_by: :prepend

  # after_create_commit -> { broadcast_prepend_later_to "quotes" }
  # after_update_commit -> { broadcast_replace_later_to "quotes" }
  # after_destroy_commit -> { broadcast_remove_to "quotes" }
  # Lets breakdown what this magic do:
  # 1. we use an after_create_commit callback to instruct our Rails app that the expression in the
  # lambda should be executed everytime a new quote is inserted into the database

  # 2. The second part of the expression in the lambda is more complex.
  # It instructs our rails app that the HTML of the created quote should be broadcasted
  # to users subscribed to the "quotes" stream and prepended to the DOM node with the id of "quotes"
end
