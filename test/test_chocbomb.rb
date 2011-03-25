require 'helper'

require 'chocbomb/tools/images'

class TestChocbomb < Test::Unit::TestCase
  JPG_FILE = File.join(File.dirname(File.expand_path(__FILE__)), 'ressources', 'default_background.jpg')
  PNG_FILE = File.join(File.dirname(File.expand_path(__FILE__)), 'ressources', 'default_background.png')
  
  def test_jpg_image_size
    width, height = ChocBomb::Tools::Images.size(JPG_FILE)
    assert_equal(500, width)
    assert_equal(400, height)
  end

  def test_png_image_size
    width, height = ChocBomb::Tools::Images.size(PNG_FILE)
    assert_equal(500, width)
    assert_equal(400, height)
  end
end
