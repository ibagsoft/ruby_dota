---
layout: post
title: 模仿jekyll的mini_blog(进阶篇)
tags: class、module、yml、send、define_method、method_missing
description: 元数据编程优化mini_blog
---



> 可通过添加微信公共帐号`icodekata`，或者微博帐号`姜志辉iS`与我讨论


书接[上文][first]。这一集我们不准备给mini_blog添加任何功能，而是换另一个角度来尝试对原有内容的重新梳理。最终的代码量不但不会增加，反而会减少。

让我们先从代码的重复说起吧。

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

## Blog类

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

在完成这个测试场景之前，让我们先来看看Ruby中的class。

### class

`class Blog;end`方法相当于声明一个名为Blog的Class类型对象。等同于`Blog = Class.new`。但是不要在使用了`class Blog;end`之后再接着使用`Blog = Class.new`。

正如我之前所述，当我们使用`class Blog;end`时，相当于使用`Blog = Class.new`创建了一个名为Blog的Class类型对象。而这个`Blog类对象`可以通过new创建一个新的对象，这个对象的模板是Blog类型(`blog = Blog.new`)。试试看：

	Blog = Class.new
	puts Blog.class
	blog = Blog.new
	puts blog.class

blog对象是以Blog作为模板创建的，那意味着blog是Blog类的实例。但是如果这个`Blog类对象`被重新赋值了，比如`Blog = String.new`。那么这个时候blog是什么类型的实例呢？

所以，当我们定义一个对象为Class类型的对象时，这个对象是不能被改变的。它是常量。

让我们总结一下：

`class Blog;end`相当于使用`Blog = Class.new`声明了一个名为Blog的Class类型的常量，而这个常量可以作为类使用`Blog.new`创建它自己的实例。

### new

如需创建Blog的实例，可使用`Blog.new`。默认情况下，new方法会自动调用在类中定义的`initialize`方法。比如：

	class Blog
		def initialize
			puts "~= Blog.new"
		end
	end

	blog = Blog.new

那么`initialize`会不会就是`Blog.new`方法呢？

默认情况下，在调用new方法的同时也会调用`initialize`方法。让我们来试试这段代码：

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

Blog.new会调用在Class类中定义的new方法而不是在Blog类中定义的initialize方法。可是为什么在使用Blog.new的时候会调用在Class中定义的new呢？

### method

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


如果blog.class里也没有定义呢？比如

	blog = Blog.new 'my_blog'
	puts blog.to_s

`to_s`方法并没有在Blog类中定义。在调用blog的方法时，应该去blog.class(也就是Blog)中去查找定义吗？如你所见Blog类中并没有定义`to_s`的方法。那这个`to_s`是从哪里来的呢？答案是，如果Blog类中没有定义，那么Blog类就会沿着它的继承体系向上查找，直到找到该方法则返回。但是不要着急从Blog.superclass，或者Blog.superclass.superclass中去寻找。因为Ruby的继承除了从类中单继承之外，还可以来自mixin的引入(比如include(module))，而`to_s`恰恰来自Ruby类的一个核心Module--Kernel。可以使用grep从Kernel中查找到这个方法：

	puts Blog.ancestors
	puts Kernel.instance_methods(false).grep /to_s/

通过ancestors方法可以打开Blog类，一直找到它的祖宗八辈:)。而`to_s`实际上来自于Kernel模块。而Kernel模块中包含了大量的实用方法，可以使用Kernel.instance_methods方法获取它提供的方法列表。你会惊奇的发现，那些看起来非常像Ruby关键字的方法很多都是来自于这个模块。

让我们总结一下：

当调用一个方法时，Ruby按照“先向右一步，再向上查找”。向右一步，是指首先它会寻找到对象的class，可通过`.class`方法获取；向上查找，是指如果在它class的instance_methods没有查找到，那么就会沿着它的祖先ancestors一直向上查找，直到找到这个方法为止。

现在让我们来回答上一节提出的问题：为什么在使用Blog.new的时候会调用在Class中定义的new呢？
Blog类也是一个对象。根据“先向右一步，再向上查找”的原则，Blog.new实际上调用的应该是在Blog.class(也就是Class)中定义的new方法。

### property

Ruby中的属性其实还是方法，只是看起来像属性而已。如具体读写操作的`blog.name`实际上是在Blog中定义的两个方法：

	class Blog
		def name=(value)
			@name = value
		end
		def name
			@name
		end
	end

	blog = Blog.new
	blog.name = 'my_blog'
	puts blog.name

这种定义非常的繁琐。Ruby给了一个更加简单的属性定义方法attr_accessor:

	class Blog
		attr_accessor :name
	end

通过`attr_accessor`定义的属性即可读又可写。如果只想具有其中一种职能。可以通过attr_reader或者attr_writer完成。attr_reader定义的属性只具有可读操作，而attr_writer则正好相反，只具有可写操作。

在介绍完了class所需要的基本功能之后，可以尝试完成blog.rb了。

我完成的版本如下：

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

上例中我没有提供写的属性，是因为在测试场景中并没有使用到写的特性。只写让程序通过的代码，如果真的需要这个场景，那就添加一个测试场景。无测试，不代码。

现在我们有了`layouts_dir`、`site_dir`、`posts_dir`、`layouts_default_file`、`site_index_file`等属性。默认情况下，它们会采用默认的路径。惯例重于配置，当用户不准备修改系统的配置时，就采用默认的配置项。这是一个很酷的原则。但是，当用户需要设置自己的配置项时，又该怎么办呢？

## 自定义配置项

我想允许用户自定义配置项是必须支持的功能。与Java的习惯不同，Ruby更喜欢采用yml来完成自定义的配置。

### yml

yml的格式相对于xml来说要简单的多。在blog.rb的同级目录中添加一个_config.yml文件如下：

	posts_dir: _posts
	site_dir: site

注意在key与value之间最少有一个空格作为分隔。

读取yml的方法已经被内置在了ruby的核心库中，因此不需要使用gem进行安装，直接在blog.rb文件的顶部添加`require "yaml"`引用即可：

	require "yaml"

	class Blog
		def get_config
			YAML.load_file('_config.yml').each do |k,v|
				puts "#{k}=#{v}"
			end
		end
	end

	blog = Blog.new
	blog.get_config

现在我们可以得到在_config.yml中的自定义属性了。

可是，怎么设定这些属性值呢？要知道我们获取的只是代表属性的字符串而已，它是不能直接调用的。

### send

在Ruby中调用一个方法时，通常会使用点(.)标记符。如`blog.get_config`。

但这不是唯一的方法。动态调用方法send可以取代标记符(.)完成调用。比如可以使用`blog.send "get_config"`取代`blog.get_config`。如果有参数呢？可以试试`blog = Blog.send :new,'my_blog'`。

为什么在`blog.send "get_config"`调用get_config时使用的是字符串("get_config")，而在`blog = Blog.send :new,'my_blog'`调用`initialize`时采用的是符号(:new)。它们有什么区别吗？答案是在当前的场景下没有什么区别。你可以认为符号( Symbol)是一种更轻量级的字符串。因此，当需要作为标识符出现时，往往会采用符号多于字符串。

现在我们的装备库里又多了一样武器，当知道一个方法的标识时，就可以通过send调用它。通过get_config方法获取用户和自定义配置，然后将v作为属性值赋值给k属性就可以了。

但是，但是....

在使用send方法时，必须指明send调用的是谁的方法。而在开发语境中，我们怎么知道具体是哪个Blog类的实例调用了send方法呢？在C家族的语言里习惯使用this，而Ruby则喜欢用self来代指当前对象。那么现在有了调用的对象，调用的属性以及属性值，我们还在等什么？

	def get_config
		YAML.load_file('_config.yml').each do |k,v|
			self.send "#{k}=",v
		end
	end

因为用到了“=”，所以需要为属性添加设置方法。完整的版本如下：

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

哎呀！好累。现在我们终于可以自定义配置项了，而且就算用户没有设置，我们也会使用默认的属性值。唯一美中不足的是，代码太长了，先不说维护起来是否容易，就Coding而言，也真是一个庞大的工程。我们是程序员，但不是打字员。

那么，谁能证明？！

##元编程

[first]: http://ibagsoft.github.io/ruby_dota/blog-with-jekyll/