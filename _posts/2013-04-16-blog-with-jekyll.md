---
layout: post
title: 模仿jekyll的简易博客
tags: IO操作、单元测试、正则表达式、markdown、数组的使用
description: 模仿jekyll的结构，使用markdown格式的文件制作博客，自动生成html格式的博客
---


[本文配套源码][src]

my_blog是一个简易的blog生成框架。使用者不需要关心blog的原理，只需要将blog书写成markdown格式，然后将其copy到blog站点的_posts目录下即可。系统会自动:

- 根据_layouts下的default.html文件当作页面布局，将所有的md文件渲染成html文件放置在_site目录下
- 自动寻找_posts目录下的md文件将其渲染成`md文件名/index.html`结构的html文件放置在_site目录下
- 将所有不以_开头的文件或者目录全部copy至_site目录下
- 读取_config.yml文件的信息成为用户自定义信息，供index.html使用

_site目录即是用户的站点，用户可以使用index.html文件作为主页面，然后从主页面进入到各个blog页面。

我们可以将这个案例分解为以下几个用户故事。

##用户故事: 自动生成blog文档结构

像ROR一样，可以使用命令自动生成blog框架。
其默认的框架结构如下：
_layouts 为布局模板目录。其中默认包含一个default.html模板文件
_posts 为博客文件
_config.yml 为站点配置信息
index.md 为博客首页

###任务1：创建目录

my_blog最少需要两个目录：_layouts和_posts。我们需要完成一个可以创建目录的函数create_dir(dir_name)

让我们先为这个任务添加单元测试(my_blog_test.rb):
	
	
	# encoding:utf-8
	# 因为使用了中文，所以需要使用encoding:uft-8指定使用的字符集
	require "test/unit" #引用test/unit，使用ruby自带的单元测试

	def create_dir(dir_name)
		#在此完成你的代码
	end

	class MyBlogTest < Test::Unit::TestCase  #定义一个单元测试类MyBlogTest
		def test_create_dir	#定义一个测试,测试需要以test开头
			layouts = '_layouts'
			posts = '_posts'
			create_dir(layouts)	#create_dir是我们需要完成的代码
			create_dir(posts)
			assert File.directory?(layouts)	#验证_layouts存在
			assert File.directory?(posts)	#验证_posts目录存在
		end
	end

这个示例的目的，为了帮助大家了解ruby中帮助的使用。可以通过`ri Dir`或者`ri File`查看关于Dir或者File的帮助。回车键可以读取下一行，如果需要退出ri，可使用`q`键退出。关于ri环境的安装可以查看根目标下的环境安装一节。
也可以使用irb进入测试环境验证实验代码。使用`exit`退出irb。
查看Dir类，找到我们需要的方法mkdir。可以使用`ri Dir.mkdir`查看更详细的信息(注意大小写，Ruby是区分大小写的)。在create_dir方法中完成你的代码。

如果你完成了create_dir方法。可以在create_dir方法所在文件的当前目录使用`ruby my_blog_test.rb`文件来执行这个测试。如果正确，显示界面应该如下:
![result](/images/my_blog_test_result.png)
`.`表示测试通过。

希望大家自己完成create_dir方法。

如果需要和我的代码对比，它可能是这样：

	def create_dir(dir_name)
		unless File.directory? dir_name #如果目录不存在，那么
			Dir.mkdir dir_name
		end
	end
	
它不是标准答案，只是恰恰可以完成罢了。

###任务2：创建文件

my_blog需要我们完成三个文件的生成：index.md、_config.yml和_layouts目录下的default.html。
开始之前我们需要两个知识点：

- File.new

使用`ri File.new`查看File.new的帮助说明。
其中mode参数可以使用'r'或者'w'来分别表示读和写，在此不需要多讲。
使用File.new方法可以创建一个文件类型的对象。new是Ruby对象中创建对象的方式，它实际上调用的是`initialize`方法：

	class MyClass #定义一个MyClass的类型
		def initialize	#构造函数
		end
		def my_method
			puts 'hello,world'
		end
	end

	obj = MyClass.new	#调用initialize创建MyClass类型的对象
	obj.my_method	#调用my_method方法

因此，如果我们使用f获取File.new创建的对象，那么f就可以调用File类里的实例方法(该部分会在类的真相里详细讲述)。

	f = File.new 'test.txt','w'	#以写的模式创建一个test.txt文件，用f持有它
	f.puts 'Hello'	#写一个带回车的行
	f.write 'world'	#写一行，不带回车
	f.close #关闭这个文件

因此我们可以通过File.new创建一个对象，然后利用f向文件中写内容。但是内容如果是不定的，比如我们向index.md和_config.yml里写的默认内容一定不一样，使用File.new就会有一定的局限性。

- 代码块

代码块可以帮助我们解决这个问题。我们在做某一项操作时(比如创建文件)，并不知道用户会如何操作这个文件。我们当然可以向File.new一样创建这个文件，然后获取这个对象，如果操作文件由用户自行决定。但也意味着用户必须自己关闭这个文件以及其它相关操作。更多的时候，其它操作序列我们都是知道的，仅仅是其中的某一步操作我们并不了解，这个时候我们可以使用代码让程序变得更灵活。

	def my_method
		puts "open file"	#先打开一个文件
			yield			#不知道如何操作，交给用户后期绑定
		puts "close file"	#最后关闭文件
	end

	my_method{puts "write file"}	#将写文件这事后期绑定给my_method的yield
	
但是如果用户没有提供后期的操作怎么办呢？我们可以使用`if block_given?`来进行判断。而且我们也还可以为用户的后期操作绑定参数：

	def my_method
		puts "open file"
		yield "this's args" if block_given? #将"this's args"作为参数传递给代码块
		puts "close file"
	end

	my_method{|args| puts args}	#|args|中的args即是"this's args"

其中{}描述的代码块也可以使用do...end来表示。一般情况下，在单行的时候我们习惯使用{}；而在多行的时候我们使用do...end。如：

	def my_method
		puts "open file"
		yield "this's args" if block_given? #将"this's args"作为参数传递给代码块
		puts "close file"
	end

	my_method do |args|
		puts args
	end	#do...end 等同于 {}

现在让我们File.open的使用

	File.open('test.txt', "w") do |file|
		file.puts "Hello"
		file.write "World"
	end
	
现在让我们添加单元测试：
	
	# encoding:utf-8
	# 因为使用了中文，所以需要使用encoding:uft-8指定使用的字符集
	require "test/unit" #引用test/unit，使用ruby自带的单元测试
	require 'yaml'

	def create_file(file_name)
		#在此完成你的代码
	end

	class MyBlogTest < Test::Unit::TestCase  #定义一个单元测试类MyBlogTest
		def test_create_html
			index = 'index.md'
			create_file index do |f|
				f.write '<h1>'
				f.write 'hello,world'
				f.write '</h1>'
			end
			result = File.open(index).readlines.join
			assert_equal '<h1>hello,world</h1>',result
		end
		def test_create_yml
			config = '_config.yml'
			create_file config do |f|
				f.puts 'title: my_blog'	#key:空格value
				f.puts 'description: blog_description'
			end
			conf = YAML.load_file(config)#从yml中读取配置信息
			assert_equal "my_blog",conf["title"]
			assert_equal "blog_description",conf["description"]
		end
	end
	
`test_create_yml`方法中使用了ruby中常用的格式yml。使用`require "yaml"`引用yaml类库，`YAML.load_file(yml_file)`可以从yml文件中读取配置信息，test_create_yml方法演示了yaml类库的使用。

使用`ri File.open`查看File.open类库，完成create_file方法。

如果需要和我的代码对比，它可能是这样：

	# encoding:utf-8
	# 因为使用了中文，所以需要使用encoding:uft-8指定使用的字符集
	require "test/unit" #引用test/unit，使用ruby自带的单元测试
	require "yaml"

	def create_file(file_name)
		File.open(file_name, "w") do |file|
			yield file if block_given?
		end
	end

	class MyBlogTest < Test::Unit::TestCase  #定义一个单元测试类MyBlogTest
		def test_create_html
			index = 'index.md'
			create_file index do |f|
				f.write '<h1>'
				f.write 'hello,world'
				f.write '</h1>'
			end
			result = File.open(index).readlines.join
			assert_equal '<h1>hello,world</h1>',result
		end
		def test_create_yml
			config = '_config.yml'
			create_file config do |f|
				f.puts 'title: my_blog'
				f.puts 'description: blog_description'
			end
			conf = YAML.load_file(config)
			assert_equal "my_blog",conf["title"]
			assert_equal "blog_description",conf["description"]
		end
	end
	
现在我们有了create_dir和create_file函数，当然可以帮助我们生成blog的初始目录和文件：

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

等等，我们都做了什么？为什么不直接使用Dir.mkdir或者File.open呢。好吧，这两个任务的目标是为了让你熟悉使用Ruby代码，慢慢培养语感，还有就是学习怎么在Ruby环境下使用单元测试。

###任务3：清理现场

如果我们运行单元测试，会发现运行时生成的目录和文件并没有被删除，遗留在了系统中。对于有洁癖的程序员当然是无法忍受。不仅如何，遗留的系统没有被删除，当我们更改程序时，因为文件已存在，测试代码并不能如实的反映程序的真实情况。让我们来搞定这些事。

- teardown

在单元测试类MyBlogTest中，添加teardown方法。teardown可以在每个测试方法运行之后自动被调用。将清理现场(单元测试时产生的目录和文件)的代码加入到teardown中，如下所示：

	def teardown
		['_layouts','_posts'].each do |dir|
			Dir.delete dir if File.directory? dir
		end
		['_config.yml','index.md','_layouts/index.html'].each do |file|
			File.delete file if File.exists? file
		end
	end

- setup

DRY,不要重复你自己。单元测试中有很多重复的代码应该被提取出来，比如`_layouts`这种多处出现的变量应该被归置在一个指定的地点。与teardown相反，setup则是在每个测试运行之前自动调用，常常用来初始化在测试中需要使用到的变量。我们可以将所有定义默认目录和文件的变量归置在setup方法中。但需要使用@符来定义变量。因为默认方式定义的变量只存于定义的函数生命周期内，这意味着在其它函数中无法访问。如果使用@定义变量，那么该变量将会存在于对象的整个生命周期内。所以，我们也可以直接将@声明的变量称之为对象变量。更改后的代码如下：

	class MyBlogTest < Test::Unit::TestCase  #定义一个单元测试类MyBlogTest
		def setup
			@layouts_dir = '_layouts'
			@posts_dir = '_posts'
			@config = '_config.yml'
			@index_md_file = '_index.md'
			@index_html_file = File.join @layouts_dir,'index.html'
		end
		def teardown
			[@layouts_dir,@posts_dir].each do |dir|
				Dir.delete dir if File.directory? dir
			end
			[@config,@index_md_file,@index_html_file].each do |file|
				File.delete file if File.exists? file
			end
		end
		def test_create_dir	#定义一个测试,测试需要以test开头
			create_dir(@layouts_dir)	#create_dir是我们需要完成的代码
			create_dir(@posts_dir)
			assert File.directory?(@layouts_dir)
			assert File.directory?(@posts_dir)
		end
		def test_create_html
			create_file @index_md_file do |f|
				f.write '<h1>'
				f.write 'hello,world'
				f.write '</h1>'
			end
			result = File.open(@index_md_file).readlines.join
			assert_equal '<h1>hello,world</h1>',result
		end
		def test_create_yml
			create_file @config do |f|
				f.puts 'title: my_blog'
				f.puts 'description: blog_description'
			end
			conf = YAML.load_file(@config)
			assert_equal "my_blog",conf["title"]
			assert_equal "blog_description",conf["description"]
		end
	end
	
- 将逻辑代码与测试代码分离

将逻辑代码和测试代码放置在一起，很显然违背了单一职责原则。无论是逻辑还是测试代码任何部分发生变动时，都会造成my_blog_test.rb文件发生变化。因此，需要将逻辑代码和测试代码放置在不同的文件中。从my_blog_test.rb中将逻辑代码提取出来，保存为my_blog.rb文件：

	def create_dir(dir_name)
		unless File.directory? dir_name #如果目录不存在，那么
			Dir.mkdir dir_name
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
	
my_blog_test.rb需要使用到my_blog.rb中的逻辑，因此，需要在测试代码中添加对my_blog.rb文件的引用：

	require "test/unit"
	require "yaml"
	require "./my_blog"

	class MyBlogTest < Test::Unit::TestCase
		# 测试代码被省略
	end

##用户故事: 转换markdown为html

markdown格式用来写blog还是比较靠谱的。只需要少量的markdown标记，而不打扰写作者的思路。写作者只需要将完成的md文件保存在_posts目录下，系统会自动搜索_posts目录下的所有md文件，然后将其转化为以md文件名为目录下的index.html文件。

###任务1：读取所有md文件

Ruby为集合的处理提供了大量的方法，可以通过`ri Array`来查看Array类的详细说明。
对于具体的方法可使用`ri Array.方法名`来查看该方法的具体使用，如`ri Array.each`、`ri Array.map`、`ri Array.collect`…，在`irb`中尝试它们的具体使用。重点尝试Array.select方法：

	result = [3,66,12,77,4,32].select do |item|
		item if (item > 10)
	end

	puts result
	
如上例所示，select方法可以从集合中提取符合条件的项组成新的集合。或许我们可以从_posts目录中利用select方法选择符合条件的文件。

如何从一堆文件中选择md文件呢？或许正则表达式可以帮助我们。说到正则表达式，我们可以试试如何在一堆的方法列表中获取我们需要的方法。让我们进入`irb`环境。

尝试输入`File.methods`，会看到大量的方法列表，然后在一堆的方法列表中寻找需要的方法确实不太方便。我们可以使用正则表达式。比如我们想找到以`to_`开头的方法可以尝试`File.methods.grep /^to_/`；如果想寻找以`name`结尾的方法，可以尝试`File.methods.grep /name$/`。那么如果我们记不得一个方法的具体名称，只记得这个方法名里面有一个`_`字符，可以尝试使用` File.methods.grep /^[0-9a-zA-Z]+_[0-9a-zA-Z]+$/`。`[0-9a-zA-Z]`表示可以是数字或者字母的任何一个匹配，`[0-9a-zA-Z]+`则表示可以有1到若干个数字或字母，如果使用`*`号，则表示可以有0到若干个数字或者字母。`_`就表示在这些数据或者字符中间必然有一个`_`字符。然而有一些字符属于特殊字符，如`.`就表示可以与任意字符相匹配，比如`File.methods.grep /./`其实和`File.methods`所得到的结果是一样的。如果我们确实需要查询一个包含`.`字符的方法，则需要为`.`加上`\`,就像这样`\.`,如果尝试`File.methods.grep /\./`则不会找到任何方法。

grep方法使用的是正则表达式。用`//`可以直接声明正则表达式，在`irb`环境中直接尝试`//.class`就可以证明这一点。在`//`中书写正则表达式可以通过`=~`查看是否与某个字符段相匹配。比如使用`puts "sample.txt" =~ /\.txt$/`可以找到sample.txt文本中与`\.txt$`匹配的位置，如果查找不到，则返回空。`/\.txt$/`表示该字符串是否以`.txt`结尾。

好了，让我们来完成`is_md_file?`方法，以使得`md_marker_test.rb`通过：

	require "test/unit"

	def is_md_file?(file_name)
		# 在此处完成你的代码
	end

	class MdTest < Test::Unit::TestCase
		def test_md_file
			assert !is_md_file?("test.txt")
			assert is_md_file?('test.md')
		end
	end
	
下面是我的实现，做个借鉴：

	def is_md_file?(file_name)
		file_name =~ /\.md$/
	end
	
使用`ri Dir`仔细查找，发现可以通过`dir = Dir.entries('_posts')`获取_posts目录下的所有文件,使用irb询问dir的类型`dir.class`,知道`Dir.entries('_posts')`返回的是一个字符串的数组，那么我们可以定义一个方法`get_mds(files)`来获取文件数组中所有的md文件。
整理一下思路，完成下面的单元测试：

	require "test/unit"

	def get_mds(files)
		# 在这里完成你的代码
	end

	class MdTest < Test::Unit::TestCase
		def test_get_mds
			files = ["a.txt",'b.rb','c.md','d.md']
			mds = get_mds(files)
			assert_equal ['c.md','d.md'],mds
		end
	end
	
这是我完成的代码：

	def get_mds(files)
		files.select do |file|
			is_md_file? file
		end
	end
	def is_md_file?(file_name)
		file_name =~ /\.md$/
	end
	
### 任务2：md2html
将博书的博客呈现给阅读者，常见的有两种方法。一种是将md文件转化为html文件，将html文件直接返回给阅读者。另一种是根据用户的选择从md文件中读取内容，根据上下文生成html返回给阅读者。我们在my_blog里使用的是前者。

- 将md的文件内容转化为html格式

那么如何将md的文件内容转化为html格式呢？使用`File.open`来读取md内容你应该早就想到了。让我们观察一下md的样式片断:`#这是H1##这是H2`不难判断`#`符号实际上对应的是html中的`<h1></h1>`,而`##`符号则对应的是html中的`<h2></h2>`标记。更多内容我们可以通过搜索引擎来查找markdown获取。
如果我们需要一个将md的文件内容转化为html形式的方法，采用正则表达式应该不难办到。不要想太多，试试用最简单的方法使下面的测试通过：

	require "test/unit"

	def md_to_html(md_content)
		# 请在这里完成你的代码
	end

	class MdTest < Test::Unit::TestCase
		def test_md_to_html
			md_content = "#subject"
			html_content = md_to_html(md_content)
			assert_equal "<h1>subject</h1>\n",html_content
		end
	end
	
为什么在预期值中多添加一个`\n`?因为`<h1>`不是更应该单独一行吗？无论是在html语法上，还是在格式的美观上。
我做了一个简单的实现，参考一下：

	def md_to_html(md_content)
		"<h1>#{md_content.sub('#','')}</h1>\n" if md_content =~ /^#/
	end

也就是说我们需要实现一个md到html文件的语法转化器。
Oh!My God!那我们需要把所有的标记全部做个对应。你当然可以做这件事，你行的，加油！我看好你噢。
至于我么。我不喜欢重复发明轮子。
通常情况下，可以尝试多几种查询是否有现成轮子的方法。比如搜索引擎，或者`gem search -r markdown`,又或者直接到这里`http://rubygems.org`。
说到markdown的轮子，我个人比较喜欢`rdiscount`.
通过`gem install rdiscount`安装rdiscount。这样我们就可以使用它了。如下所示：

	require "test/unit"
	require "rdiscount"

	def md_to_html(md_content)
		RDiscount.new(md_content).to_html
	end

	class MdTest < Test::Unit::TestCase
		def test_md_to_html
			md_content = "#subject"
			html_content = md_to_html(md_content)
			assert_equal "<h1>subject</h1>\n",html_content
		end
	end
	
- 将_posts中的md文件转化为_site目录下的html

我们需要在这个任务中将_posts中的md文件转化为index。这个任务应该不太难。通过前面的md_to_html的方法将获取生成后的html内容写到_site目录下就可以了。
先不要看下面的内容，自己动手试试。

你是否发现了两个小问题：1、如果将xxx.md转化到_site/xxx/index.html，那么就必须先创建_site目录，然后才能完成写的操作。2、如果md格式的代码中有中文，就会出现乱码的现象。

是的，事情并不像我们想像的那么简单。在Coding的世界里，你不动手永远不知道会发生什么意想不同的问题。所以，无论是学习Coding还是实际工作，必须养成勤动手的好习惯。

让我们先来解决目录的问题。`create_dir`方法应该可以支持多级目录的情况，比如`create_dir _site/xxx`的格式。
让我们来改变一下my_blog_test.rb的test_create_dir测试：

	def test_create_dir	#定义一个测试,测试需要以test开头
		@blog_dir = "_site/blogs"
		create_dir(@layouts_dir)	#create_dir是我们需要完成的代码
		create_dir(@posts_dir)
		create_dir(@blog_dir)
		assert File.directory?(@layouts_dir)	#验证_layouts存在
		assert File.directory?(@posts_dir)	#验证_posts目录存在
		assert File.directory?(@blog_dir)
	end

在原有基础上添加了@blog_dir的路径形式。更改my_blog.rb文件中的create_dir方法，使这个单元测试通过。
你可能需要查看一下String.split和Array.join的方法。
反正我使用到了：

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
	
清理现场，将@blog_dir变量提取到单元测试的setup方法中。
别忘了我们还得清理生成的目录和文件，试试在测试文件中的teardown方法中搞定它。
以下是我的版本：

	def teardown
		[@layouts_dir,@posts_dir,@blog_dir].each do |dir|
			Dir.delete dir if File.directory? dir
		end
		blog_path = @blog_dir
		@blog_dir.split('/').reverse.each	do |dir|
			Dir.delete blog_path if File.directory? blog_path
			blog_path = blog_path.chomp "/#{dir}"
		end
		[@config,@index_md_file,@index_html_file].each do |file|
			File.delete file if File.exists? file
		end
	end

现在让我们来解决第二个中文乱码的问题。在html中，如果有中文的话，需要使用`<meta charset='utf-8'>`在html页面中声明。因此在写文件时，需要先写入这个声明，然后再写入转换完成以后的html。如下所示：

	def made_html(dir)
		mds = get_mds(Dir.entries(dir))
		mds.each do |md|
			md_content = File.open(md).readlines.join
			html_content = md_to_html(md_content)
			blog_dir = "_site/#{md.sub '.md',''}"
			create_dir blog_dir
			File.open(File.join(blog_dir,"index.html"), "w") do |f|
				f.puts "<meta charset='utf-8'>"
				f.write html_content
			end
		end
	end
	
##用户故事3：清理现场

未完待续
	
	
[src]: https://github.com/ibagsoft/ruby_dota/tree/gh-pages/src/my_blog_with_jekyll "src"