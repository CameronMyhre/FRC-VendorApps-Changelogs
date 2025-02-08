# app.rb
require 'sinatra'
require 'httparty'
require 'nokogiri'

# ------------------------------
# Configuration: List of vendor apps
# ------------------------------   
VENDOR_APPS = {
    'WPILib' => 'https://github.com/wpilibsuite/allwpilib/releases',
    'CTRE'   => 'https://github.com/CrossTheRoadElec/Phoenix-Releases/releases',
    'Photonvision'    => 'https://github.com/PhotonVision/photonvision/releases',
    'PathPlanner'    => 'https://github.com/mjansen4857/pathplanner/releases',
    'AdvantageKit'    => 'https://github.com/Mechanical-Advantage/AdvantageKit/releases',
}
# ------------------------------
# Helper Methods for Scraping
# ------------------------------

# Fetch and parse a releases page given a URL.
def get_release_page(url)
    response = HTTParty.get(url)
    Nokogiri::HTML(response)
  end
  
  # Given a vendor's release page URL, return an array of releases.
  # Each release is a hash with keys: :version and :body.
  def fetch_releases(url)
    page = get_release_page(url)
    
    # These selectors are based on GitHub’s current HTML.
    # Adjust these selectors for different vendor apps if needed.
    release_versions = page.css('span.f1 a')
    release_bodies   = page.css('div.my-3')

    releases = []
    release_versions.each_with_index do |version, index|

        # Get the raw HTML of the release body
        raw_body = release_bodies[index] ? release_bodies[index].inner_html : "No changelog available"
        # Remove whitespace between tags (e.g. between </p> and <p>)
        clean_body = raw_body.gsub(/>\s+</, '><').strip

        releases << {
            version: version.text.strip,
            
            # Use inner_html to preserve formatting (e.g. paragraphs, line breaks, etc.)
            body: release_bodies[index] ? release_bodies[index].inner_html.strip : "No changelog available"
        }
    end
    releases
  end
  
  # ------------------------------
  # Sinatra Route(s)
  # ------------------------------
  
  get '/' do

    # Prepare a list of vendor names.
    @vendors = VENDOR_APPS.keys
  
    # Build a hash to store for each vendor:
    # - The list of releases (to populate the dropdown)
    # - The selected release (if any) based on the form parameters.
    @vendor_data = {}
  
    @vendors.each do |vendor|
      url = VENDOR_APPS[vendor]
      releases = fetch_releases(url)

      # Use the vendor name as the parameter key.
      selected_version = params[vendor] if params[vendor] && !params[vendor].empty?
      selected_release = releases.find { |r| r[:version] == selected_version } if selected_version
  
      @vendor_data[vendor] = {
        releases: releases,
        selected: selected_release
      }
    end
  
    erb :index
  end   