require "rdiscount"
require "liquid"

module FilePath
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
					clear_dir(path)
				else
					File.delete path
				end
			end
		end
		Dir.delete dir_path
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
end