(function() {
  var form = document.querySelector(".newsletter form");

  if (document.cookie.match("subscribed=true") && form) {
    document.querySelector("body").classList.add("subscribed");

    return;
  }

  form.addEventListener("submit", function() {
    var time = new Date();

    time.setMilliseconds(time.getMilliseconds() + 365 * 86400000);

    document.cookie = "subscribed=true; path=/; expires=" + time.toUTCString();
  }, false);
})();
