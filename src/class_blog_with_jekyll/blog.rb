require "yaml"

class Blog
	def initialize(blog_name)
		@blog_name = blog_name
		@attributes = {}
		get_config
	end
	def get_config
		YAML.load_file('_config.yml').each do |k,v|
			self.send "#{k}=",File.join(@blog_name,v)
		end
	end

	def get_path(name)
		dir_regexp =  /_dir$/
		file_regexp = /_file$/
		dirs = name.split('_')
		if dir_regexp =~ name
			dirs.pop
		elsif file_regexp =~ name
			dirs.pop
			html_file = dirs.pop
		end
		path = dirs.collect{|dir| "_#{dir}"}.join("/")
		path = File.join(path,"#{html_file}.html") if html_file
		path
	end

	def method_missing(method,*args)
		attribute = method.to_s
		if attribute =~ /=$/
			@attributes[attribute.chop] = File.join @blog_name,args[0]
		else
			@attributes[attribute] = File.join(@blog_name,get_path(attribute)) unless @attributes[attribute]
			@attributes[attribute]
		end
	end
end

blog = Blog.new 'test_blog'
puts blog.site_dir
puts blog.layouts_dir