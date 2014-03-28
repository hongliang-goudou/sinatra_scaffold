get %r{(/.*)\/$} do
  redirect params[:captures].first
end
