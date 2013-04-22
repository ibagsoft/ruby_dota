require "test/unit"
require "./file_path"

class FilePathTest < Test::Unit::TestCase
	include FilePath
	def setup
		@blog_dir = "test_blog"
		@site_dir = File.join @blog_dir,"_site"
		@layouts_dir = File.join @blog_dir,"_layouts"
		@posts_dir = File.join @blog_dir,"_posts"
		@default_layout = File.join @layouts_dir,'default.html'
		@file_path = File.join @site_dir,"index.html"
		@md_file = 'test.md'
	end
	def teardown
		clear_dir @blog_dir
	end
	def test_get_dir
		assert_equal @site_dir,get_dir(@file_path)
	end
	def test_create_file
		create_file @file_path,"hello,world"
		assert_equal "hello,world",File.open(@file_path).readlines.join
	end
	def test_create_dir
		create_dir(@site_dir)
		create_dir(@layouts_dir)
		create_dir(@posts_dir)
		assert Dir.exist?(@site_dir)
		assert Dir.exist?(@layouts_dir)
		assert Dir.exist?(@posts_dir)
	end
	def test_is_md_file?
		assert !is_md_file?('text.txt')
	end
	def test_get_mds
		md_file = 'c.md'
		result = get_mds(["a.txt",'b.html',md_file])
		assert_equal 1,result.length
		assert_equal md_file,result[0]
	end
	def test_md_to_html
		md_content = '#content'
		html_content = "<h1>content</h1>\n"
		assert_equal html_content,md_to_html(md_content)
	end
	def test_render
		layout_content = "<p>{{content}}</p>"
		blog_content = 'hello,world'
		html_content = "<p>hello,world</p>"
		result = render(layout_content,blog_content)
		assert_equal html_content,result
	end
end