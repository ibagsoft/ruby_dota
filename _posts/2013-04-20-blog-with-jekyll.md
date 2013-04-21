---
layout: post
title: 模仿jekyll的mini_blog(进阶篇)
tags: class、module、yml、send、define_method、method_missing
description: 元数据编程优化mini_blog
---



> 可通过添加微信公共帐号`icodekata`，或者微博帐号`姜志辉iS`与我讨论


书接[上文][first]。这一集我们不准备给mini_blog添加任何功能，而是换另一个角度来尝试对原有内容的重新梳理。最终的代码量不但不会增加，反而会减少。

让我们先从代码的重复说起吧。

## 不要重复你自己。

思考一下这两条命令：

- `ruby blog.rb create my_blog`
- `ruby blog.rb create your_blog`

它们创建的blog除了blog_name之外几乎是一样的:

- 同样以blog_name/_posts目录作为md工作目录
- 同样以blog_name/_layouts目录作为布局工作目录
- 同样以blog_name/_layouts/default.html文件作为默认布局模板
- 同样以blog_name/_site目录作为生产目录
- 同样以blog_name/_site/index.html作为默认导航页面
- 同样以blog_name/_site/md名称/index.html文件作为最终博客路径

在每次创建博客的时候，都需要重复组装这些路径。比如`layouts_dir`：

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

不只`layouts_dir`,还有`site_dir`、`posts_dir`、`layouts_default_file`...。它们只是blog_name发生了变化，但是外在的行为是一样的。

于是，我们可以创建一个blog模具，根据blog_name，创建不同的对象，这些对象都有layouts_dir、site_dir、posts_dir、default_layouts_file等属性，但是属性值又各不相同。

我们需要的是：

### Blog类

让我们在blog_test.rb中添加这个场景的验证条件：

	require "test/unit"
	require "./blog" # 引用本地的blog.rb文件

	class BlogTest < Test::Unit::TestCase	
		def test_blog_attributes
			blog = Blog.new 'test_blog'
			assert_equal "test_blog/_posts",blog.posts_dir
			assert_equal "test_blog/_layouts",blog.layouts_dir
			assert_equal "test_blog/_site",blog.site_dir
			assert_equal "test_blog/_layouts/default.html",blog.layouts_default_file
			assert_equal "test_blog/_site/index.html",blog.site_index_file
		end
	end	

通过`Blog.new 'test_blog'`创建一个名为'test_blog'的博客对象。该博客对象应该具有`layouts_dir`、`site_dir`、`posts_dir`、`layouts_default_file`、`site_index_file`等属性。

我完成的blog.rb如下：

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

可以在`irb`环境中，通过`require "./blog"`将blog.rb加哉到测试环境中。尝试`Blog.instance_methods(false)`，查看Blog类提供的对象方法列表。

#### class Blog

`class Blog;end`方法相当于声明一个名为Blog的Class类型对象。等同于`Blog = Class.new`。但是不要在使用了`class Blog;end`之后再接着使用`Blog = Class.new`.不信你随便感受下。

正如我之前所述，当我们使用`class Blog;end`时，相当于使用`Blog = Class.new`创建了一个名为Blog的Class类型对象。而这个`Blog类对象`可以通过new创建一个新的对象，这个对象的模板是Blog类型(`blog = Blog.new`)。试试看：

	Blog = Class.new
	puts Blog.class
	blog = Blog.new
	puts blog.class

blog对象是以Blog作为模板创建的，那意味着blog是Blog类的实例。但是如果这个`Blog类对象`被重新赋值了，比如`Blog = String.new`。那么这个时候blog是什么类型的实例呢？

所以，当我们定义一个对象为Class类型的对象时，这个对象是不能被改变的。它是常量。

让我们总结一下：

`class Blog;end`相当于使用`Blog = Class.new`声明了一个名为Blog的Class类型的常量，而这个常量可以作为类使用`Blog.new`创建它自己的实例。

#### new

如需创建Blog的实例，可使用`Blog.new`。默认情况下，new方法会自动调用在类中定义的`initialize`方法。比如：

	class Blog
		def initialize
			puts "~= Blog.new"
		end
	end

	blog = Blog.new

那么`initialize`会不会就是`Blog.new`方法呢？

不是！

只是默认情况下，在调用类new方法的同时也会同时调用`initialize`方法。让我们来试试这段代码：

	class Blog
		def initialize
			puts "~= `Blog.new"
		end
	end

	class Class
		def new
			puts "this's new"
		end
	end

	blog = Blog.new

会输出“this's new”而不是"~= `Blog.new"。那就意味着Blog.new会调用在Class类中定义的new方法而不是在Blog类中定义的initialize方法。可是为什么在使用Blog.new的时候会调用在Class中定义的new呢？

#### methods 与 instance_methods

这就得说说类和实例之间的关系了。看看下面这段代码：

	class Blog
		def initialize(blog_name)
			@blog_name = blog_name
		end
		def posts_dir
			File.join @blog_name,'_posts'
		end
	end

	blog = Blog.new 'my_blog'

	puts blog.methods == Blog.instance_methods

测试`puts blog.methods == Blog.instance_methods`得到的结果为真。 这说明blog对象的methods与Blog类的instance_methods列表是相等的。

再进一步，修改上面的代码如下：

	class Blog
		def initialize(blog_name)
			@blog_name = blog_name
		end
		def posts_dir
			File.join @blog_name,'_posts'
		end
	end

	blog = Blog.new 'my_blog'

	class Blog
		def posts_dir
			"new posts_dir"
		end
	end

	puts blog.posts_dir

blog对象是使用最早的Blog创建的。其后我们重新定义了Blog类，并且重写了posts_dir方法。然而当我们调用`puts blog.posts_dir`时，输出的结果却是"new posts_dir"。这说明blog对象中并没有存储posts_dir方法，在运行`blog.posts_dir`时，Ruby解释器会将这个请求指向在blog.class(即Blog类)中定义的posts_dir方法。

[first]: http://ibagsoft.github.io/ruby_dota/blog-with-jekyll/
