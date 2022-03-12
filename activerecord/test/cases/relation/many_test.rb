

require "cases/helper"
require "models/post"
require "models/comment"
require "models/author"
require 'debug'

module ActiveRecord
  class ManyTest < ActiveRecord::TestCase
    fixtures :posts, :authors, :topics, :comments, :author_addresses

    def test_ex      
      assert_equal(
        Post.joins(:author).all.to_sql, 
        Author.all.with_many.posts.values.to_sql
      )

      assert_equal(
        Comment.joins(post: :author).to_sql,
        Author.all.with_many.posts.comments.values.to_sql
      )

      assert_equal(
        Comment.joins(post: :author).containing_the_letter_e.to_sql,
        Author.all.with_many.posts.comments.containing_the_letter_e.values.to_sql
      )

      assert_equal(
        Comment.joins(post: :author).where(Author.arel_table[:id].eq(1)).containing_the_letter_e.to_sql, 
        Author.where(id: 1).with_many.posts.comments.containing_the_letter_e.values.to_sql
      )
      
      assert_equal(
        Comment.joins(post: :author).where(Author.arel_table[:id].eq(1)).where(Post.arel_table[:id].eq(1)).containing_the_letter_e.to_sql, 
        Author.where(id: 1).with_many.posts.where(id: 1).comments.containing_the_letter_e.values.to_sql
      )

      assert_equal(
        Comment.joins(post: :author).where(Author.arel_table[:id].eq(1)).where(Post.arel_table[:id].eq(1)).where(id: 1).containing_the_letter_e.to_sql, 
        Author.where(id: 1).with_many.posts.where(id: 1).comments.where(id: 1).containing_the_letter_e.values.to_sql
      )
      
      #binding.break
      #author = Author.create(name: '12235813')
      #(0...1).each{|i| author.posts << Post.create(title: i, body: i)}

      #pp Author.all.with_many.posts.comments.containing_the_letter_e.body.split(/\s+/).upcase.values

    end
  end
end