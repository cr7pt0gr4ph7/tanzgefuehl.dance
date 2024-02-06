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

    if !options['only_production'] || Jekyll.env == "production"
      @batch.each do |item|
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

          result = AutoprefixerRails.process(css, options)
          file.write(result)
          map_file&.write(result.map)
        ensure
          file&.close
          map_file&.close
        end
      end
    end

    @batch.clear
  end
end

Jekyll::Autoprefixer::Autoprefixer.prepend AutoprefixerPatch
