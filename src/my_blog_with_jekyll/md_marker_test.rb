require "test/unit"
require "rdiscount"
require "./my_blog"

def get_mds(files)
	files.select do |file|
		is_md_file? file
	end
end
def is_md_file?(file_name)
	file_name =~ /\.md$/
end
def md_to_html(md_content)
	RDiscount.new(md_content).to_html
end
def made_html(dir)
	mds = get_mds(Dir.entries(dir))
	mds.each do |md|
		md_content = File.open(md).readlines.join
		html_content = md_to_html(md_content)
		blog_dir = "_site/#{md.sub '.md',''}"
		create_dir blog_dir
		File.open(File.join(blog_dir,"index.html"), "w") do |f|
			f.puts "<meta charset='utf-8'>"
			f.write html_content
		end
	end
end

class MdTest < Test::Unit::TestCase
	def test_md_file
		assert !is_md_file?("test.txt")
		assert is_md_file?('test.md')
	end
	def test_get_mds
		files = ["a.txt",'b.rb','c.md','d.md']
		mds = get_mds(files)
		assert_equal ['c.md','d.md'],mds
	end
	def test_md_to_html
		md_content = "#subject"
		html_content = md_to_html(md_content)
		assert_equal "<h1>subject</h1>\n",html_content
	end
end