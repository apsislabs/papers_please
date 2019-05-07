class Attachment
  attr_accessor :post

  def initialize(post:)
    @post = post
  end
end
