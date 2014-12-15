module FileStrategy
  def check
    context.execute :mkdir, "-p", deploy_path.join("repo")
  end

  def test
    false
  end

  def clone
    true
  end

  def update
    `mkdir -p #{File.dirname(path)}`
    `tar -zcf #{path} --exclude .jekyll-assets-cache --exclude .git --exclude _site --exclude tmp .`

    context.upload! path, "/#{path}"

    `rm #{path}`
  end

  def release
    context.execute :mkdir, "-p", release_path
    context.execute :tar, "-xmf" "/#{path}", "-C", release_path
    context.execute :rm, "/#{path}"
  end

  def fetch_revision
    `git log --pretty=format:'%h' -n 1 HEAD`
  end

  def path
    "tmp/#{fetch(:application)}.tar.gz"
  end
end
