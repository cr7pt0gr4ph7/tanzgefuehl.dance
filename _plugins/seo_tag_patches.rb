module SeoTagDropExtensions
  TITLE_SEPARATOR = " | "

  def page_title
    if page["use_full_page_title"]
      @page_title ||= title
    else
      @page_title ||= format_string(page["title"]) || site_title
    end
  end

  def title
    @title ||= begin
      if site_title && format_string(page["title"])
        format_string(page["title"]) + TITLE_SEPARATOR + site_title
      elsif site_description && site_title
        site_title + TITLE_SEPARATOR + site_tagline_or_description
      elsif
        format_string(page["title"]) || site_title
      else
        site_title
      end
    end
  end
end

Jekyll::SeoTag::Drop.prepend SeoTagDropExtensions
