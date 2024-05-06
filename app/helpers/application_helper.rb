module ApplicationHelper

  def header_options(opts={})
    default_header_options = {
      title: nil,
      header_extended: false
    }

    default_header_options.merge!(opts)
  end
end
