class GenerateQrService
	attr_reader :user

  def initialize(user)
  	@user = user
  end

	include Rails.application.routes.url_helpers
  
  require 'rqrcode'

  def call
  	qr_url = url_for(
      controller: 'users',
      action: 'show',
      id: @user.id,
      only_path: false,
      host: "#{ENV['DOMAIN_WITH_PROTOCOL']}",
      source: 'from_qr'
      )
    qrcode = RQRCode::QRCode.new(qr_url)
    png = qrcode.as_png(
      bit_depth: 1,
      border_modules: 4,
      color_mode: ChunkyPNG::COLOR_GRAYSCALE,
      color: "black",
      file: nil,
      fill: "white",
      module_px_size: 6,
      resize_exactly_to: false,
      resize_gte_to: false,
      size: 120
    )
    img_name = SecureRandom.hex

    IO.binwrite("tmp/#{img_name}.png", png.to_s)

    blob = ActiveStorage::Blob.create_after_upload!(
      io: File.open("tmp/#{img_name}.png"),
      filename: img_name,
      content_type: "png"
      )

  	@user.qr_code.attach(blob)
  end
end
