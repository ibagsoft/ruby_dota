# encoding:utf-8
class Blog
	def initialize(app_name)
		@app_name = app_name
	end
	def create_dir(dir_name)
		path = []
		dir_name.split('/').each do |dir|
			path << dir
			dir_path = path.join '/'
			Dir.mkdir dir_path unless File.directory? dir_path
		end
	end
	def create_dirs()
		['_layouts','_posts'].each do |dir_name|
			create_dir File.join @app_name,dir_name
		end
	end
	def create_file(file_name)
		File.open(file_name, "w") do |file|
			yield file if block_given?
		end
	end
	def create_layout_default()
		layout_default = File.join @app_name,'_layouts/default.html'
		create_file layout_default do |f|
			f.puts "<html><head><meta charset='utf-8'/><title>my_blog</title></head><body>"
			f.puts "<h1>My Blog</h1><div id='content'>"
			f.puts "{{content}}"
			f.write "</div></body></html>"
		end
	end
	def create_config_yml()
		config_yml = File.join @app_name,'_config.yml'
		create_file config_yml
	end
	def create_files
		create_layout_default()
		create_config_yml()
	end
	def create
		create_dirs()
		create_files()
	end
end

if ARGV.length == 1
	app_name = ARGV[0]
	blog = Blog.new app_name
	blog.create
else
	puts "请使用`ruby create_blog.rb app_name`的样式"
end