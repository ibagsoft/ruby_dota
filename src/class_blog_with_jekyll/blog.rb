require "yaml"
require "./file_path"

class Blog

	include FilePath

	def initialize(blog_name)
		@blog_name = blog_name
		@attributes = {}
		get_config
	end

	def get_layouts_default_content(*args)
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

	def create
		create_layouts_dir
		create_posts_dir
		create_layouts_default_file get_layouts_default_content
	end

	def create_blog(md_name)
		md_path = File.join posts_dir,md_name
		blog_path = self.send "site_#{md_name.sub('.md','') }_blog"
		md_text = File.open(md_path).readlines.join
		content = render get_layouts_default_content,md_to_html(md_text)
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

	def generate
		mds = []
		mds = Dir.entries(posts_dir) - ['.','..'] if Dir.exists?posts_dir
		mds.each do |md|
			create_blog md
		end
		content = render get_layouts_default_content,index_content(mds)
		create_file site_index_file,content
	end

	private

	def get_config
		YAML.load_file('_config.yml').each do |k,v|
			self.send "#{k}=",v
		end
	end
	def get_path(name)
		dir_regexp =  /_dir$/
		file_regexp = /_file$/
		blog_regexp = /_blog$/
		dirs = name.split('_')
		if dir_regexp =~ name
			dirs.pop
		elsif file_regexp =~ name
			dirs.pop
			html_file = "#{dirs.pop}.html"
		elsif blog_regexp =~ name
			dirs.pop
			html_file = File.join dirs.pop,"index.html"
		end
		path = dirs.collect{|dir| "_#{dir}"}.join("/")
		path = File.join(path,html_file) if html_file
		File.join(@blog_name,path)
	end

	def method_missing(method,*args)
		attribute = method.to_s
		if attribute =~ /=$/
			@attributes[attribute.chop] = File.join @blog_name,args[0]
		else
			create_dir_regexp = /^create_(.+_dir)$/
			create_file_regexp = /^create_(.+_file)$/

			if attribute =~ create_dir_regexp
				attribute = attribute.match(create_dir_regexp)[1]
				@attributes[attribute] = get_path(attribute)
				create_dir @attributes[attribute]
			end
			if attribute =~ create_file_regexp
				attribute = attribute.match(create_file_regexp)[1]
				@attributes[attribute] = get_path(attribute)
				create_file @attributes[attribute],args[0]
			end

			@attributes[attribute] = get_path(attribute) unless @attributes[attribute]
			@attributes[attribute]
		end
	end
end

def check_usage
	unless ARGV.length == 2 && ['create','generate'].include?(ARGV[0])
		puts "Usage: `ruby blog.rb create|generate app_name`"
		exit
	end
end

if $0 == __FILE__
	check_usage
	blog = Blog.new ARGV[1]
	blog.send ARGV[0].chomp
end