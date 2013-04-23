require "test/unit"
require "./blog"

class BlogTest < Test::Unit::TestCase
	def setup
		@blog_dir = 'test_blog'
		@blog = Blog.new @blog_dir
	end

	def teardown
		@blog.clear_dir @blog_dir
	end

	def test_create_layouts_dir
		@blog.create_layouts_dir
		assert Dir.exist? @blog.layouts_dir
	end

	def test_create_posts_dir
		@blog.create_posts_dir
		assert Dir.exist? @blog.posts_dir
	end

	def test_create_default_layout
		@blog.create_layouts_default_file 'test'
		assert File.exist? @blog.layouts_default_file
		assert_equal 'test',File.open(@blog.layouts_default_file).readlines.join
	end

	def test_get_layouts_default_content
		default_content = @blog.get_layouts_default_content
		assert default_content.include? "{{content}}"
	end

	def test_create_blog
		test_md = File.join @blog.create_posts_dir,'test.md'
		@blog.create_file test_md,"#hello,blog"
		@blog.create_blog 'test.md'
		assert File.exists?(@blog.site_test_blog)
		assert File.open(@blog.site_test_blog).readlines.join.include?("<h1>hello,blog</h1>\n")
	end

	def test_index_content
		mds = ['a.md','b.md']
		result = @blog.index_content(mds)
		blog_regexp = /<a\s+href='.+?\/index.html'>/
		arr = []
		result.scan(blog_regexp) do |item|
			md_reg = /<a\s+href='(.+)\/index.html'>/
			arr << "#{item.match(md_reg)[1]}.md"
		end
		assert_equal [],mds - arr
	end
end