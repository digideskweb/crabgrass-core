#
# override how validation errors are drawn
#
ActionView::Base.field_error_proc = Proc.new do |html_tag, instance_tag|
  %Q(<div class="control-group error">#{html_tag}</div>).html_safe
end
