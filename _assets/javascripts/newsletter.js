(function() {
  if (document.cookie.match("subscribed=true")) {
    document.querySelector("body").classList.add("subscribed");

    return;
  }

  document.querySelector(".newsletter form").addEventListener("submit", function() {
    var time = new Date();

    time.setMilliseconds(time.getMilliseconds() + 365 * 86400000);

    document.cookie = "subscribed=true; path=/; expires=" + time.toUTCString();
  }, false);
})();
