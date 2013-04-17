require "test/unit"
require "liquid"

def layout_render(layout,blog)
	template = Liquid::Template.parse(layout)
	template.render('content' => blog)
end

class LayoutTest < Test::Unit::TestCase
	def test_layout_render
		layout_content = "<p>{{content}}</p>"
		blog_content = "this's blog content"
		result = layout_render(layout_content,blog_content)
		assert_equal "<p>this's blog content</p>",result
	end
end