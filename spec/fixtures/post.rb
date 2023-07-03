# frozen_string_literal: true

class Post
  attr_accessor :published

  def self.all
    @all ||= Array.new(3) { Post.new }
  end
end
