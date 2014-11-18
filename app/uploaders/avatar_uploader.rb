# encoding: utf-8

class AvatarUploader < CarrierWave::Uploader::Base

  # Include RMagick or MiniMagick support:
  include CarrierWave::RMagick
  # include CarrierWave::MiniMagick

  # Choose what kind of storage to use for this uploader:
  storage :file
  # storage :fog

  # Override the directory where uploaded files will be stored.
  # This is a sensible default for uploaders that are meant to be mounted:
  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  # Provide a default URL as a default if there hasn't been a file uploaded:
  # def default_url
  #   # For Rails 3.1+ asset pipeline compatibility:
  #   # ActionController::Base.helpers.asset_path("fallback/" + [version_name, "default.png"].compact.join('_'))
  #
  #   "/images/fallback/" + [version_name, "default.png"].compact.join('_')
  # end

  # Process files as they are uploaded:
  # process :scale => [200, 300]
  #
  # def scale(width, height)
  #   # do something
  # end

  # Create different versions of your uploaded files:
  version :thumb do
    process :crop
    process :resize_to_limit => [200, 200]
  end

  version :profile_size do
    process :crop
    resize_to_limit(50, 50)
  end

  version :large do
    resize_to_limit(500, 500)
  end

  def crop
    if model.coord_x.present?
      resize_to_limit(500,500)
      manipulate! do |img|
        x = model.coord_x.to_i
        y = model.coord_y.to_i
        w = model.coord_w.to_i
        h = model.coord_h.to_i
        img.crop!(x,y,w,h)# for rmagick

        # size = w << 'x' << h
        # offset = '+' << x << '+' << y

        # img.crop "#{size}#{offset}" # Doesn't return an image...
        # img # ...so you'll need to call it yourself
      end
      # image = MiniMagick::Image.open(model.avatar.large.path)
      # crop_params = "#{model.coord_w}x#{model.coord_h}+#{model.coord_x}+#{model.coord_y}"
      # image.crop(crop_params)
      # image
    end
  end

  # Add a white list of extensions which are allowed to be uploaded.
  # For images you might use something like this:
  def extension_white_list
    %w(jpg jpeg gif png)
  end

  # Override the filename of the uploaded files:
  # Avoid using model.id or version_name here, see uploader/store.rb for details.
  # def filename
  #   "something.jpg" if original_filename
  # end

end
