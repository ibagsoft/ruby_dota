class Blog
	def initialize(blog_name)
		@blog_name = blog_name
	end
	def posts_dir
		File.join @blog_name,'_posts'
	end
	def layouts_dir
		File.join @blog_name,'_layouts'
	end
	def site_dir
		File.join @blog_name,'_site'
	end
	def layouts_default_file
		File.join layouts_dir,'default.html'
	end
	def site_index_file
		File.join site_dir,'index.html'
	end
end