require "test/unit"
require "./blog"

class BlogTest < Test::Unit::TestCase
	def setup
		@blog_dir = "test_blog"
		@site_dir = File.join @blog_dir,"_site"
                @config_dir = File.join @site_dir,"_config" # test_blog/_site/_config
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
		create_dir(@config_dir)
		assert Dir.exist?(@site_dir)
		assert Dir.exist?(@layouts_dir)
		assert Dir.exist?(@posts_dir)
		assert Dir.exist?(@config_dir)
	end
	def test_create_dirs
		create_dirs @blog_dir
		assert Dir.exist? @blog_dir
		assert Dir.exist? @layouts_dir
		assert Dir.exist? @posts_dir
	end
	def test_create_default_layout
		create_default_layout @blog_dir,'test'
		assert File.exist? @default_layout
		assert_equal 'test',File.open(@default_layout).readlines.join
	end
	def test_get_default_layout_content
		default_content = get_default_layout_content
		assert default_content.include? "{{content}}"
	end
	def test_create
		create @blog_dir
		assert File.exist? @default_layout
		assert_equal get_default_layout_content,File.open(@default_layout).readlines.join
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
	def test_create_blog
		create_file File.join(@posts_dir,@md_file),"#test"
		create_blog @blog_dir,@md_file
		blog_file = File.join File.join(@site_dir,@md_file.sub('.md','')),'index.html'
		assert File.exists? blog_file
		assert File.open(blog_file).readlines.join.include?("<h1>test</h1>")
	end
	def test_index_content
		mds = ['a.md','b.md']
		result = index_content(mds)
		blog_regexp = /<a\s+href='.+?\/index.html'>/
		arr = []
		result.scan(blog_regexp) do |item|
			md_reg = /<a\s+href='(.+)\/index.html'>/
			arr << "#{item.match(md_reg)[1]}.md"
		end
		assert_equal [],mds - arr
	end
end
