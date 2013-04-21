require "yaml"

class Blog
	def initialize(blog_name)
		@blog_name = blog_name
		get_config
	end
	def get_config
		YAML.load_file('_config.yml').each do |k,v|
			self.send "#{k}=",v
		end
	end
	def posts_dir=(path)
		@posts = path
	end
	def posts_dir
		@posts = File.join @blog_name,'_posts' unless @posts
		@posts
	end
	def layouts_dir=(path)
		@layouts = path
	end
	def layouts_dir
		@layouts = File.join @blog_name,'_layouts' unless @layouts
		@layouts
	end
	def site_dir=(path)
		@site = path
	end
	def site_dir
		@site = File.join @blog_name,'_site' unless @site
		@site
	end
	def layouts_default_file=(path)
		@layouts_default_file = path
	end
	def layouts_default_file
		@layouts_default_file = File.join layouts_dir,'default.html' unless @layouts_default_file
		@layouts_default_file
	end
	def site_index_file=(path)
		@site_index_file = path
	end
	def site_index_file
		@site_index_file = File.join site_dir,'index.html' unless @site_index_file
		@site_index_file
	end
end

blog = Blog.new 'test_blog'
puts blog.site_dir
puts blog.layouts_dir