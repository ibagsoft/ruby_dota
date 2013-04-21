require "test/unit"
require "./blog"

class BlogTest < Test::Unit::TestCase	
	def test_blog_attributes
		blog = Blog.new 'test_blog'
		assert_equal "test_blog/_posts",blog.posts_dir
		assert_equal "test_blog/_layouts",blog.layouts_dir
		assert_equal "test_blog/_site",blog.site_dir
		assert_equal "test_blog/_layouts/default.html",blog.layouts_default_file
		assert_equal "test_blog/_site/index.html",blog.site_index_file
	end
end