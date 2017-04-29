if command -v jekyll &>/dev/null ; then

  alias jf="ps aux | grep jekyll"     #jf: Finds PID of Jekyll to kill server

  jb() {
    # builds jekyll with _config.yml
    if [ -f ./"Gruntfile.coffee" ]; then
      echo "running: 'npm-exec grunt dev'"
      npm-exec grunt dev "$@"
    elif [ "$(type -P 'myJekyll')" ]; then
      myJekyll -tb "$@"
    else
      bundle exec jekyll build "$@"
    fi
  }

  jbd() {
    # builds jekyll with _config.yml and drafts
    if [ -f ./"Gruntfile.coffee" ]; then
      echo "running: 'npm-exec grunt devFuture'"
      npm-exec grunt devFuture "$@"
    elif [ "$(type -P 'myJekyll')" ]; then
      myJekyll -tbD "$@"
    else
      bundle exec jekyll build "$@"
    fi
  }

  jbp() {
    # builds jekyll with _config_production.yml
    if [ -f ./"Gruntfile.coffee" ]; then
      echo "running: 'npm-exec grunt prod'"
      npm-exec grunt prod "$@"
    elif [ "$(type -P 'myJekyll')" ]; then
      myJekyll -tb --config _config_production.yml "$@"
    else
      bundle exec jekyll build --config _config_production.yml "$@"
    fi
  }

  js() {
    # Serves Jekyll with _config.yml and incremental builds
    if [ -f ./"Gruntfile.coffee" ]; then
      echo "running: 'npm-exec grunt serve'"
      npm-exec grunt serve "$@"
    elif [ "$(type -P 'myJekyll')" ]; then
      myJekyll -sIt "$@"
    else
      bundle exec jekyll serve --incremental "$@"
    fi
  }

  jss() {
    # Serves Jekyll with _config.yml and incremental builds
    if [ -f ./"Gruntfile.coffee" ]; then
      echo "running: 'npm-exec grunt serveStage'"
      npm-exec grunt serveStage "$@"
    elif [ "$(type -P 'myJekyll')" ]; then
      myJekyll -sIt --config _config_staging.yml "$@"
    else
      bundle exec jekyll serve --incremental --config _config_staging.yml "$@"
    fi
  }

  jsd() {
    # Serves Jekyll with _config.yml and incremental builds and drafts
    if [ -f ./"Gruntfile.coffee" ]; then
      echo "running: 'npm-exec grunt serveFuture'"
      npm-exec grunt serveFuture "$@"
    elif [ "$(type -P 'myJekyll')" ]; then
      myJekyll -sID "$@"
    else
      bundle exec jekyll serve --incremental --drafts --future "$@"
    fi
  }
fi