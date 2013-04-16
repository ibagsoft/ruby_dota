def create_dir(dir_name)
	dirs = dir_name.split '/'
	path = []
	dirs.each do |dir|
		path << dir
		dir_path = path.join '/'
		unless File.directory? dir_path
			Dir.mkdir dir_path
		end
	end
end

def create_file(file_name)
	File.open(file_name, "w") do |file|
		yield file if block_given?
	end
end

def create_dirs(app_name)
	layouts_dir = File.join app_name,'_layouts'
	posts_dir = File.join app_name,'_posts'
	[app_name,layouts_dir,posts_dir].each do |dir_name|
		create_dir dir_name
	end
end
def create_files(app_name)
	layouts_dir = File.join app_name,'_layouts'
	config_file = File.join app_name,'_config.yml'
	index_html_file = File.join layouts_dir,'index.html'
	index_md_file = File.join app_name,'index.md'
	[config_file,index_html_file,index_md_file].each do |file_name|
		create_file file_name
	end
end
def create_blog(app_name)
	create_dirs app_name
	create_files app_name
end