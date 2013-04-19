
require "rdiscount"
require "liquid"

def create_dir(dir_name)
	path = []
	dir_name.split('/').each do |dir|
		path << dir
		dir_path = path.join '/'
		Dir.mkdir dir_path unless Dir.exists? dir_path
	end
end

def get_dir(file_path)
	arr = file_path.split '/'
	arr.pop
	arr.join('/')
end

def create_file(file_path,content)
	dir_path = get_dir(file_path)
	create_dir dir_path unless Dir.exists?dir_path
	File.open(file_path, "w") do |f|
		f.write content
	end
end

def clear_dir(dir_path)
	return unless Dir.exists? dir_path
	files = Dir.entries(dir_path) - ['.','..']
	if files.length > 0
		files.each do |file|
			path = File.join dir_path,file
			if Dir.exists?(path)
				clear_dir(path)	#如果是目录，递归调用clear_dir
			else
				File.delete path
			end
		end
	end
	Dir.delete dir_path
end

def create_dirs(blog_name)
	blog_dir = blog_name
	layouts_dir = File.join blog_dir,"_layouts"
	posts_dir = File.join blog_dir,"_posts"
	[layouts_dir,posts_dir].each do	|dir|
		create_dir dir
	end
end

def create_default_layout(blog_name,content)
	blog_dir = blog_name
	layouts_dir = File.join blog_dir,"_layouts"
	default_layout = File.join layouts_dir,'default.html'
	create_file default_layout,content
end

def get_default_layout_content(*args)
	if args.length == 1
		File.open(args[0]).readlines.join
	else
		content = []
		content << "<html><head><meta charset='utf-8'/><title>my_blog</title></head><body>"
		content << "<h1>My Blog</h1><div id='content'>"
		content << "{{content}}"
		content << "</div></body></html>"
		content.join
	end
end

def is_md_file?(file_name)
	file_name =~ /\.md$/
end

def get_mds(files)
	files.select do |file|
		is_md_file? file
	end
end

def md_to_html(md_content)
	RDiscount.new(md_content).to_html
end

def render(layout_text,blog_text)
	template = Liquid::Template.parse(layout_text)
	template.render('content' => blog_text)
end

def create_blog(blog_name,md)
	md_path = File.join blog_name,"_posts/#{md}"
	blog_path = File.join File.join(File.join(blog_name,'_site'),md.sub('.md','')),"index.html" 
	
	md_text = File.open(md_path).readlines.join
	html_content = md_to_html(md_text)
	content = render get_default_layout_content,html_content

	create_file  blog_path,content
end

def index_content(md_files)
	content = []
	content << "<ul>"
	md_files.each do |md_file|
		blog_dir = md_file.sub '.md',''
		content << "<li><a href='#{blog_dir}/index.html'>#{blog_dir}</a></li>"
	end
	content << "</ul>"
	content.join
end

def create(blog_name)
	create_dirs blog_name
	create_default_layout blog_name,get_default_layout_content
end

def generate(blog_name)
	mds = []
	posts_dir = File.join(blog_name,"_posts")
	mds = Dir.entries(posts_dir) - ['.','..'] if Dir.exists?posts_dir
	mds.each do |md|
		create_blog blog_name,md
	end
	content = render get_default_layout_content,index_content(mds)
	index_path = File.join blog_name,'_site/index.html'
	create_file index_path,content
end

def check_usage
	unless ARGV.length == 2 && ['create','generate'].include?(ARGV[0])
		puts "Usage: `ruby blog.rb create|generate app_name`"
		exit
	end
end

if $0 == __FILE__
	check_usage
	method = ARGV[0]
	blog_name = ARGV[1]
	if method == 'create'
		create blog_name
	elsif method == 'generate'
		generate blog_name
	end
end