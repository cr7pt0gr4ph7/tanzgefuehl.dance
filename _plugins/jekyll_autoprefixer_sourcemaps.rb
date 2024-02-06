module AutoprefixerPatch
  def process
    options = @site.config['autoprefixer'] || {}

    # Controls when source maps shall be generated.
    #
    # never — causes no source maps to be generated at all
    # always — source maps will always be generated
    # development — source maps will only be generated if the site is in development environment
    write_sourcemaps = case options['sourcemaps']
    when 'never'
      false
    when 'always'
      true
    when 'development'
      Jekyll.env == 'development'
    when nil
      false # Default value
    else
      Jekyll.logger.warn("Ignoring unknown value '#{options['sourcemaps']}' for autoprefixer.sourcemaps. Disabling source map generation instead.")
      false
    end

    return if options['only_production'] && Jekyll.env != "production"

    @batch.each do |item|
      if options['exclude_static_files'] && item.is_a?(Jekyll::StaticFile)
        # HACK: Exclude static files - this should normally be done by using
        #       site.pages.each instead of site.each_site_file, but we would
        #       have to patch/replace even more code for this to work.
        next
      end

      path = item.destination(@site.dest)
      map_path = "#{path}.map"

      begin
        file = File.open(path, 'r+')
        css = file.read
        file.truncate(0)
        file.rewind

        if write_sourcemaps && File.exist?(map_path)
          # If a source map already exists (e.g. because the CSS was generated from SASS files),
          # read and transform the existing sourcemap.
          map_file = File.open(map_path, 'r+')
          map = map_file.read
          map_file.truncate(0)
          map_file.rewind
        elsif write_sourcemaps
          # Sourcemap does not exist yet, but should be created
          map_file = File.open(map_path, 'w+')
          map = true
        else
          # No sourcemaps should be written
          map_file = nil
          map = nil
        end

        filename = File.basename(path)

        file_options = { 'map' => { 'prev' => map }, 'from' => filename, 'to' => filename }
          .merge(options)
          .transform_keys { |key| key.to_sym }

        result = AutoprefixerRails.process(css, file_options)
        Jekyll.logger.error("Failed to create sourcemap for #{filename}") if write_sourcemaps && result.map.nil?
        file.write(result)
        map_file&.write(result.map)
      ensure
        file&.close
        map_file&.close
      end
    end

    @batch.clear
  end
end

Jekyll::Autoprefixer::Autoprefixer.prepend AutoprefixerPatch
