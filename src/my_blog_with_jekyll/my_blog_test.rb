# encoding:utf-8
# 因为使用了中文，所以需要使用encoding:uft-8指定使用的字符集
require "test/unit" #引用test/unit，使用ruby自带的单元测试
require "yaml"
require "./my_blog"

class MyBlogTest < Test::Unit::TestCase  #定义一个单元测试类MyBlogTest
	def setup
		@layouts_dir = '_layouts'
		@posts_dir = '_posts'
		@config = '_config.yml'
		@index_md_file = '_index.md'
		@index_html_file = File.join @layouts_dir,'index.html'
		@blog_dir = "_site/blogs/test"
	end
	def teardown
		[@layouts_dir,@posts_dir,@blog_dir].each do |dir|
			Dir.delete dir if File.directory? dir
		end
		blog_path = @blog_dir
		@blog_dir.split('/').reverse.each	do |dir|
			Dir.delete blog_path if File.directory? blog_path
			blog_path = blog_path.chomp "/#{dir}"
		end
		[@config,@index_md_file,@index_html_file].each do |file|
			File.delete file if File.exists? file
		end
	end
	def test_create_dir	#定义一个测试,测试需要以test开头
		create_dir(@layouts_dir)	#create_dir是我们需要完成的代码
		create_dir(@posts_dir)
		create_dir(@blog_dir)
		assert File.directory?(@layouts_dir)	#验证_layouts存在
		assert File.directory?(@posts_dir)	#验证_posts目录存在
		assert File.directory?(@blog_dir)
	end
	def test_create_html
		create_file @index_md_file do |f|
			f.write '<h1>'
			f.write 'hello,world'
			f.write '</h1>'
		end
		result = File.open(@index_md_file).readlines.join
		assert_equal '<h1>hello,world</h1>',result
	end
	def test_create_yml
		create_file @config do |f|
			f.puts 'title: my_blog'
			f.puts 'description: blog_description'
		end
		conf = YAML.load_file(@config)
		assert_equal "my_blog",conf["title"]
		assert_equal "blog_description",conf["description"]
	end
end