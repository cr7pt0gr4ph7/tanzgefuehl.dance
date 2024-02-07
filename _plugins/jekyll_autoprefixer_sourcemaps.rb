module AutoprefixerPatch
  def process
    options = @site.config['autoprefixer'] || {}
    return if options['only_production'] && Jekyll.env != "production"

    write_sourcemaps =
      case options['sourcemaps']
      when 'never' then false
      when 'always' then true
      when 'production' then Jekyll.env == 'production'
      when 'development' then Jekyll.env == 'development'
      when nil then false # Default value
      else
        Jekyll.logger.warn("Ignoring unknown value '#{options['sourcemaps']}' for autoprefixer.sourcemaps. Disabling source map generation instead.")
        false
      end

    # Process all files that were regenerated during this Jekyll build
    @batch.each do |item|
      options['exclude_static_files'] && item.is_a?(Jekyll::StaticFile)
        # HACK: Exclude static files - this should normally be done by using
        #       site.pages.each instead of site.each_site_file, but we would
        #       have to patch/replace even more code for this to work.
        next
      end

      path = item.destination(@site.dest)
      process_file(path, options, write_sourcemaps)
    end

    @batch.clear
  end

  private

  def process_file(path, options, write_sourcemaps)
    filename = File.basename(path)
    map_path = "#{path}.map"

    begin
      file = File.open(path, 'r+')
      css = file.read

      if write_sourcemaps && File.exist?(map_path)
        # If a source map already exists (e.g. because the CSS was generated from SASS files),
        # read and transform the existing sourcemap.
        map_file = File.open(map_path, 'r+')
        map = map_file.read
      elsif write_sourcemaps
        # Sourcemap does not exist yet, but should be created
        map_file = File.open(map_path, 'w+')
        map = true
      else
        # No sourcemaps should be written
        map_file = nil
        map = nil
      end
    
      map_options =
        if map == true then true
        elsif map then { 'prev' => map }
        else nil
        end

      file_options = { 'map' => map_options, 'from' => filename, 'to' => filename }
        .merge(options)
        .transform_keys { |key| key.to_sym }

      result = AutoprefixerRails.process(css, file_options)
      file.truncate(0)
      file.rewind
      file.write(result)

      if result.map && map_file
        map_file.truncate(0)
        map_file.rewind
        map_file.write(result.map)
      elsif write_sourcemaps
        Jekyll.logger.error("Failed to create sourcemap for #{filename}")
      end
    ensure
      file&.close
      map_file&.close
    end
  end
end

Jekyll::Autoprefixer::Autoprefixer.prepend AutoprefixerPatch
