# Jupyter and Python bundle modules offered by this app, and which ones go together.
# Loaded by ../form.yml.erb (to build the choices) and script.sh.erb (to check the
# submitted choices again), which run as the user on the OOD host. It lives in template/
# so OnDemand copies it into the session directory, where script.sh.erb is rendered.
#
# Module availability is read from this site's periodically-refreshed module snapshot
# rather than shelling out to `module avail` live: the dashboard runs in a mount
# namespace where CVMFS's nested software catalogs aren't visible, so `module` never
# gets defined there. The snapshot is a plain local file, at the cost of only being as
# fresh as its last refresh, and it only reflects one CPU architecture - script.sh.erb
# therefore checks availability again on the compute node.
require "json"

module JupyterModules
  # (guarded: the ERB files `load` this file on every render)
  unless const_defined?(:CACHE_PATH)
    CACHE_PATH = "/etc/ood/modules/cbe.json"

    # Used when the snapshot can't be read or has no entries of that kind (2026-11 values)
    FALLBACK = {
      lab: %w[
        JupyterLab/4.4.9-GCCcore-14.3.0
        JupyterLab/4.4.4-GCCcore-14.2.0
        JupyterLab/4.2.5-GCCcore-13.3.0
      ],
      notebook: %w[
        JupyterNotebook/7.4.7-GCCcore-14.3.0
        JupyterNotebook/7.4.4-GCCcore-14.2.0
        JupyterNotebook/7.2.3-GCCcore-13.3.0
      ],
      lmod: %w[
        jupyterlmod/5.3.0-GCCcore-14.3.0
        jupyterlmod/5.2.2-GCCcore-14.2.0
        jupyterlmod/5.2.2-GCCcore-13.3.0
      ],
      bundle: %w[
        SciPy-bundle/2025.07-gfbf-2025b
        SciPy-bundle/2025.07-lfbf-2025b
        SciPy-bundle/2025.06-gfbf-2025a
        SciPy-bundle/2024.05-gfbf-2024a
      ]
    }.freeze

    # Module base names offered as "Additional Python bundle"
    BUNDLE_NAMES = %w[SciPy-bundle].freeze

    # GCCcore version -> EasyBuild toolchain generation. The Jupyter modules are built
    # with GCCcore, the bundles with a full toolchain (gfbf-2025b, ...); both sit on the
    # same Python only within one generation. Add a line here for each new generation.
    GENERATIONS = {
      "12.2.0" => "2022b",
      "12.3.0" => "2023a",
      "13.2.0" => "2023b",
      "13.3.0" => "2024a",
      "14.2.0" => "2025a",
      "14.3.0" => "2025b",
      "15.2.0" => "2026a"
    }.freeze
  end

  # { lab: [...], notebook: [...], lmod: [...], bundle: [...], error: "..." or nil, missing: [...] }
  # (lmod: the jupyterlmod builds, which add a module panel to JupyterLab)
  # Never raises: a broken snapshot must not break the form; it degrades to FALLBACK
  # and says why in :error / :missing (shown in the form's help texts).
  def self.discover
    cache, error = load_cache
    found = {
      lab: full_names(cache, ["JupyterLab"]),
      notebook: full_names(cache, ["JupyterNotebook"]),
      lmod: full_names(cache, ["jupyterlmod"]),
      bundle: full_names(cache, BUNDLE_NAMES)
    }
    missing = found.select { |_, names| names.empty? }.keys
    lists = found.to_h { |kind, names| [kind, newest_first(names.empty? ? FALLBACK[kind] : names)] }
    lists.merge(error: error, missing: error ? [] : missing)
  end

  def self.load_cache
    [JSON.parse(File.read(CACHE_PATH)), nil]
  rescue StandardError => e
    [{}, "#{e.class}: #{e.message}"]
  end

  # every "fullName" (e.g. "JupyterLab/4.4.9-GCCcore-14.3.0") under the given base names
  def self.full_names(cache, base_names)
    base_names.flat_map { |k| (cache[k] || {}).values.map { |meta| meta["fullName"] } }.compact.uniq
  rescue StandardError
    []
  end

  # newest version first, so the first option (the form's default) is the newest;
  # same version by name (gfbf before lfbf)
  def self.newest_first(names)
    names.sort { |a, b| [version_of(b), a] <=> [version_of(a), b] }
  end

  def self.version_of(name)
    Gem::Version.new(name.to_s.split("/", 2)[1].to_s[/\A\d+(?:\.\d+)*/] || "0")
  rescue ArgumentError
    Gem::Version.new("0")
  end

  def self.gcccore_of(name)
    name.to_s[/-GCCcore-([\d.]+)\z/, 1]
  end

  # "2025b" for both JupyterLab/...-GCCcore-14.3.0 and SciPy-bundle/...-gfbf-2025b
  def self.generation_of(name)
    GENERATIONS[gcccore_of(name)] || name.to_s[/-[A-Za-z]+-(\d{4}[ab])\z/, 1]
  end

  def self.compatible?(jupyter_name, bundle_name)
    gen = generation_of(jupyter_name)
    !gen.nil? && generation_of(bundle_name) == gen
  end

  # JupyterNotebook modules built with the same GCCcore as a JupyterLab module
  # (the JupyterLab modules don't bundle the classic `notebook` package)
  def self.notebooks_for(lab_name, notebooks)
    gcc = gcccore_of(lab_name)
    gcc ? notebooks.select { |n| gcccore_of(n) == gcc } : []
  end

  # escape a string for a double-quoted YAML scalar (block form avoids gsub's own
  # backslash-replacement reinterpretation)
  def self.yaml_escape(s)
    s.to_s.gsub("\\") { "\\\\" }.gsub('"') { "\\\"" }.gsub("\r") { "" }.gsub("\n") { "\\n" }
  end

  # quote a string as a single safe bash argument
  def self.sh_quote(s)
    "'" + s.to_s.gsub("'") { "'\\''" } + "'"
  end
end
