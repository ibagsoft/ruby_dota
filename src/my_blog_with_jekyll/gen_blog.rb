# encoding:utf-8
require "rdiscount"
require "liquid"
class Blog
	def initialize(app_name)
		@app_name = app_name
	end
	def get_mds()
		files = Dir.entries(File.join @app_name,'_posts')
		files.select do |file|
			is_md_file? file
		end
	end
	def is_md_file?(file_name)
		file_name =~ /\.md$/
	end
	def create_dir(dir_name)
		path = []
		dir_name.split('/').each do |dir|
			path << dir
			dir_path = path.join '/'
			Dir.mkdir dir_path unless File.directory? dir_path
		end
	end
	def md_to_html(md_content)
		RDiscount.new(md_content).to_html
	end
	def layout_render(layout,blog)
		template = Liquid::Template.parse(layout)
		template.render('content' => blog)
	end
	def get_layout_content
		layout_file = File.join @app_name,"_layouts/default.html"
		File.open(layout_file).readlines.join
	end
	def made_html()
		mds = get_mds()
		mds.each do |md|
			md_content = File.open(File.join "#{@app_name}/_posts",md).readlines.join
			html_content = md_to_html(md_content)
			layout_content = get_layout_content
			content = layout_render layout_content,html_content
			blog_dir = "#{@app_name}/_site/#{md.sub '.md',''}"
			create_dir blog_dir
			File.open(File.join(blog_dir,"index.html"), "w") do |f|
				f.write content
			end
		end
	end
	def create_index
		mds = get_mds
		content = []
		content << "<ul>"
		mds.each do |md|
			blog_dir = md.sub '.md',''
			content << "<li><a href='#{blog_dir}/index.html'>#{blog_dir}</a></li>"
		end
		content << "</ul>"
		layout_content = get_layout_content
		content = layout_render layout_content,content.join
		File.open(File.join(@app_name,'_site/index.html'),"w") do |f|
			f.write content
		end
	end
end

if ARGV.length == 1
	app_name = ARGV[0]
	blog = Blog.new app_name
	blog.made_html
	blog.create_index
else
	puts "请使用`ruby create_blog.rb app_name`的样式"
end