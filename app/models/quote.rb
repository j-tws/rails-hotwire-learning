class Quote < ApplicationRecord
  belongs_to :company
  has_many :line_item_dates, dependent: :destroy

  validates :name, presence: true

  scope :ordered, -> { order(id: :desc) }

  # this line is the syntactic sugar for the below
  broadcasts_to ->(quote) { [quote.company, "quotes"] }, inserts_by: :prepend
  # previously the line broadcasts_to ->(quote) { "quotes" }, inserts_by: :prepend
  # will create a security issue because users have the same `signed-stream-name`.
  # Both users have subscribed to the Turbo::StreamsChannel thanks to the `channel` attribute
  # Therefore if we have the same `signed-stream-name` on both the accountants and the
  # eavesdropper's `Quotes#index` page, they will receive the same broadcastings.
  # This is a problem because when a quote is created, the corresponding HTML is broadcasted
  # to both the accountant and the eaves dropper.

  # So what `{ [quote.company, "quotes"] }` does under the hood is that the signed stream name is generated
  # from the array returned by the lambda that is the first argument of the `broadcasts_to`
  # method. The rules for secure broadcastings are the following
  #   1. Users who share broadcastings should have the lambda return an array with the same values
  #   2. users who shouldn't share broadcastings should have the lambda return an array with different values

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
